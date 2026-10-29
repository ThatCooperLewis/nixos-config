// calendar-bridge: HTTP/JSON access to Apple Calendar and Reminders via
// EventKit, so Stubert on nix-nuc can use them without running on the Mac.
//
// Usage: calendar-bridge <port> <token-file> <allowed-ip>...
// Only clients whose address is in the allowlist get an answer. Writes also
// need `Authorization: Bearer <token>` and `Content-Type: application/json`
// (the content type keeps a web page from POSTing to localhost).
//
// Read:
//   GET   /health
//   GET   /calendars
//   GET   /events?start=2026-10-26&end=2026-11-02[&calendar=Name]...
//   GET   /reminder-lists
//   GET   /reminders?status=open|completed|all[&list=Name]...[&due_before=...][&completed_since=...]
// Write (create and edit only; nothing can be deleted, by design):
//   POST  /events          {title, start, [end], [all_day], [calendar | calendar_id], [location], [notes], [url]}
//   PATCH /events/<id>     any of the above; recurring events also need
//                          {occurrence_start, span: "this" | "future"}
//   POST  /reminders       {title, [list | list_id], [due], [notes], [priority], [url]}
//   PATCH /reminders/<id>  any of the above, plus {completed: true|false}
//   POST  /reminder-lists  {title}: a new list in the default list's account
// In a PATCH, a null value clears an optional field (location, notes, url, due).
//
// Dates accept YYYY-MM-DD, YYYY-MM-DDTHH:MM (local time) or full ISO 8601.

import EventKit
import Foundation
import Network

let args = CommandLine.arguments
guard args.count >= 3, let port = NWEndpoint.Port(args[1]) else {
  FileHandle.standardError.write("usage: calendar-bridge <port> <token-file> <allowed-ip>...\n".data(using: .utf8)!)
  exit(2)
}
let tokenFile = args[2]
let allowed = Set(args.dropFirst(3))

let store = EKEventStore()
let workQueue = DispatchQueue(label: "calendar-bridge", attributes: .concurrent)

func log(_ msg: String) {
  print("\(ISO8601DateFormatter().string(from: Date())) \(msg)")
  fflush(stdout)
}

// Read on every write, so a re-keyed secret applies without a restart.
// nil (missing/empty file) disables writes rather than allowing them.
func writeToken() -> String? {
  guard let raw = try? String(contentsOfFile: tokenFile, encoding: .utf8) else { return nil }
  let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
  return t.isEmpty ? nil : t
}

func constantTimeEqual(_ a: String, _ b: String) -> Bool {
  let x = Array(a.utf8), y = Array(b.utf8)
  guard x.count == y.count else { return false }
  return zip(x, y).reduce(0) { $0 | ($1.0 ^ $1.1) } == 0
}

// MARK: - Access

func statusName(_ s: EKAuthorizationStatus) -> String {
  switch s {
  case .fullAccess: return "full"
  case .writeOnly: return "write_only"
  case .denied: return "denied"
  case .restricted: return "restricted"
  case .notDetermined: return "not_determined"
  @unknown default: return "unknown"
  }
}

func access() -> [String: String] {
  [
    "calendar": statusName(EKEventStore.authorizationStatus(for: .event)),
    "reminders": statusName(EKEventStore.authorizationStatus(for: .reminder)),
  ]
}

// Shows the macOS permission prompt in the GUI session on first run.
store.requestFullAccessToEvents { granted, err in
  log("calendar access granted=\(granted) \(err.map { "\($0)" } ?? "")")
}
store.requestFullAccessToReminders { granted, err in
  log("reminders access granted=\(granted) \(err.map { "\($0)" } ?? "")")
}

// MARK: - Dates

let isoOut: ISO8601DateFormatter = {
  let f = ISO8601DateFormatter()
  f.timeZone = TimeZone.current
  f.formatOptions = [.withInternetDateTime]
  return f
}()

func localFormatter(_ format: String) -> DateFormatter {
  let f = DateFormatter()
  f.locale = Locale(identifier: "en_US_POSIX")
  f.timeZone = TimeZone.current
  f.dateFormat = format
  return f
}
let dayFormat = localFormatter("yyyy-MM-dd")
let minuteFormat = localFormatter("yyyy-MM-dd'T'HH:mm")
let secondFormat = localFormatter("yyyy-MM-dd'T'HH:mm:ss")

func parseDate(_ s: String?) -> Date? {
  guard let s = s, !s.isEmpty else { return nil }
  if let d = ISO8601DateFormatter().date(from: s) { return d }
  for f in [secondFormat, minuteFormat, dayFormat] {
    if let d = f.date(from: s) { return d }
  }
  return nil
}

func isDateOnly(_ s: String) -> Bool { s.count == 10 && dayFormat.date(from: s) != nil }

func fmt(_ d: Date?) -> Any { d.map { isoOut.string(from: $0) } ?? NSNull() }

// MARK: - Serialization

func calendarJSON(_ c: EKCalendar) -> [String: Any] {
  [
    "id": c.calendarIdentifier,
    "title": c.title,
    "source": c.source?.title ?? "",
    "read_only": !c.allowsContentModifications,
  ]
}

func eventJSON(_ e: EKEvent) -> [String: Any] {
  [
    "id": e.eventIdentifier ?? "",
    "title": e.title ?? "",
    "calendar": e.calendar?.title ?? "",
    "calendar_id": e.calendar?.calendarIdentifier ?? "",
    "start": fmt(e.startDate),
    "end": fmt(e.endDate),
    "all_day": e.isAllDay,
    "location": e.location ?? NSNull(),
    "notes": e.notes ?? NSNull(),
    "url": e.url?.absoluteString ?? NSNull(),
    "recurring": e.hasRecurrenceRules,
    "attendees": (e.attendees ?? []).compactMap { $0.name },
  ]
}

func reminderJSON(_ r: EKReminder) -> [String: Any] {
  var due: Any = NSNull()
  var dueAllDay = false
  if let comps = r.dueDateComponents, let d = Calendar.current.date(from: comps) {
    dueAllDay = comps.hour == nil
    due = dueAllDay ? dayFormat.string(from: d) : isoOut.string(from: d)
  }
  return [
    "id": r.calendarItemIdentifier,
    "title": r.title ?? "",
    "list": r.calendar?.title ?? "",
    "list_id": r.calendar?.calendarIdentifier ?? "",
    "due": due,
    "due_all_day": dueAllDay,
    "completed": r.isCompleted,
    "completed_at": fmt(r.completionDate),
    "priority": r.priority,  // 0 none, 1 high, 5 medium, 9 low
    "notes": r.notes ?? NSNull(),
    "url": r.url?.absoluteString ?? NSNull(),
  ]
}

// MARK: - Request helpers

struct HTTPError: Error {
  let status: Int
  let message: String
}

func bad(_ msg: String) -> HTTPError { HTTPError(status: 400, message: msg) }

func calendars(_ type: EKEntityType, named names: [String]) throws -> [EKCalendar]? {
  let all = store.calendars(for: type)
  if names.isEmpty { return nil }  // nil = every calendar
  let wanted = Set(names.map { $0.lowercased() })
  let picked = all.filter { wanted.contains($0.title.lowercased()) }
  if picked.isEmpty {
    throw HTTPError(status: 404, message: "no calendar/list named \(names.joined(separator: ", "))")
  }
  return picked
}

// One writable calendar from {calendar|list: name} or {calendar_id|list_id: id}.
func targetCalendar(_ type: EKEntityType, _ body: [String: Any], nameKey: String, idKey: String) throws -> EKCalendar? {
  let found: EKCalendar
  if let id = body[idKey] as? String {
    guard let c = store.calendar(withIdentifier: id), c.allowedEntityTypes.contains(type == .event ? .event : .reminder)
    else { throw HTTPError(status: 404, message: "no \(nameKey) with id \(id)") }
    found = c
  } else if let name = body[nameKey] as? String {
    let matches = store.calendars(for: type).filter { $0.title.lowercased() == name.lowercased() }
    if matches.isEmpty { throw HTTPError(status: 404, message: "no \(nameKey) named \(name)") }
    if matches.count > 1 {
      let ids = matches.map { "\($0.calendarIdentifier) (\($0.source?.title ?? "?"))" }.joined(separator: ", ")
      throw HTTPError(status: 409, message: "several \(nameKey)s are named \(name); pass \(idKey): \(ids)")
    }
    found = matches[0]
  } else {
    return nil
  }
  guard found.allowsContentModifications else { throw bad("\(found.title) is read-only") }
  return found
}

func requireAccess(_ type: EKEntityType) throws {
  let s = EKEventStore.authorizationStatus(for: type)
  if s != .fullAccess {
    throw HTTPError(
      status: 503,
      message: "\(type == .event ? "Calendar" : "Reminders") access is \(statusName(s)) on the Mac")
  }
}

func str(_ body: [String: Any], _ key: String) throws -> String? {
  guard let v = body[key], !(v is NSNull) else { return nil }
  guard let s = v as? String else { throw bad("\(key) must be a string") }
  return s
}

// For optional text fields: absent = leave alone, null/"" = clear.
func applyText(_ body: [String: Any], _ key: String, _ set: (String?) -> Void) throws {
  guard let v = body[key] else { return }
  if v is NSNull { return set(nil) }
  guard let s = v as? String else { throw bad("\(key) must be a string or null") }
  set(s.isEmpty ? nil : s)
}

func applyURL(_ body: [String: Any], _ set: (URL?) -> Void) throws {
  try applyText(body, "url") { s in set(s.flatMap { URL(string: $0) }) }
}

func dueComponents(_ s: String) throws -> DateComponents {
  guard let d = parseDate(s) else { throw bad("bad date for due: \(s)") }
  let fields: Set<Calendar.Component> = isDateOnly(s)
    ? [.year, .month, .day] : [.year, .month, .day, .hour, .minute]
  var comps = Calendar.current.dateComponents(fields, from: d)
  comps.calendar = Calendar.current
  comps.timeZone = isDateOnly(s) ? nil : TimeZone.current
  return comps
}

// MARK: - Events (write)

func applyEventFields(_ e: EKEvent, _ body: [String: Any], creating: Bool) throws {
  if let t = try str(body, "title") { e.title = t }
  if let c = try targetCalendar(.event, body, nameKey: "calendar", idKey: "calendar_id") { e.calendar = c }

  let startRaw = try str(body, "start")
  let endRaw = try str(body, "end")
  // New events are all-day when start is a bare date; edits keep the current kind.
  let allDay = (body["all_day"] as? Bool) ?? (creating ? startRaw.map(isDateOnly) ?? false : e.isAllDay)
  var start = e.startDate
  var end = e.endDate
  if let s = startRaw {
    guard let d = parseDate(s) else { throw bad("bad date for start: \(s)") }
    // Keep the duration when only the start moves.
    if endRaw == nil, let oldStart = start, let oldEnd = end, !creating {
      end = d.addingTimeInterval(oldEnd.timeIntervalSince(oldStart))
    }
    start = d
  }
  if let s = endRaw {
    guard let d = parseDate(s) else { throw bad("bad date for end: \(s)") }
    end = d
  }
  guard let startDate = start else { throw bad("start is required") }
  if allDay {
    start = Calendar.current.startOfDay(for: startDate)
    // end is the last day (inclusive) for all-day events.
    end = Calendar.current.startOfDay(for: end ?? startDate)
  } else if end == nil {
    end = startDate.addingTimeInterval(3600)
  }
  guard let endDate = end, endDate >= start! else { throw bad("end must not be before start") }
  e.isAllDay = allDay
  e.startDate = start
  e.endDate = allDay ? endDate.addingTimeInterval(86399) : endDate

  try applyText(body, "location") { e.location = $0 }
  try applyText(body, "notes") { e.notes = $0 }
  try applyURL(body) { e.url = $0 }
}

func createEvent(_ body: [String: Any]) throws -> Any {
  try requireAccess(.event)
  guard let title = try str(body, "title"), !title.isEmpty else { throw bad("title is required") }
  guard try str(body, "start") != nil else { throw bad("start is required") }
  let e = EKEvent(eventStore: store)
  e.calendar = store.defaultCalendarForNewEvents
  try applyEventFields(e, body, creating: true)
  guard e.calendar != nil else { throw bad("no default calendar; pass calendar") }
  try store.save(e, span: .thisEvent, commit: true)
  log("created event \(e.eventIdentifier ?? "?") \"\(title)\" in \(e.calendar.title)")
  return eventJSON(e)
}

func editEvent(_ id: String, _ body: [String: Any]) throws -> Any {
  try requireAccess(.event)
  guard var e = store.event(withIdentifier: id) else { throw HTTPError(status: 404, message: "no event \(id)") }
  var span = EKSpan.thisEvent
  if e.hasRecurrenceRules {
    // event(withIdentifier:) returns the first occurrence; find the one meant.
    guard let occRaw = try str(body, "occurrence_start"), let occ = parseDate(occRaw) else {
      throw bad("recurring event: pass occurrence_start (its start from /events) and span (\"this\" or \"future\")")
    }
    switch try str(body, "span") {
    case "this": span = .thisEvent
    case "future": span = .futureEvents
    default: throw bad("recurring event: span must be \"this\" or \"future\"")
    }
    let day = Calendar.current.startOfDay(for: occ)
    let pred = store.predicateForEvents(withStart: day, end: day.addingTimeInterval(86400), calendars: [e.calendar])
    guard let match = store.events(matching: pred).first(where: {
      $0.eventIdentifier == id && abs($0.startDate.timeIntervalSince(occ)) < 60
    }) else { throw HTTPError(status: 404, message: "no occurrence of \(id) starting at \(occRaw)") }
    e = match
  }
  guard e.calendar.allowsContentModifications else { throw bad("\(e.calendar.title) is read-only") }
  try applyEventFields(e, body, creating: false)
  try store.save(e, span: span, commit: true)
  log("edited event \(id) \"\(e.title ?? "")\" fields=\(body.keys.sorted())")
  return eventJSON(e)
}

// MARK: - Reminders (write)

func applyReminderFields(_ r: EKReminder, _ body: [String: Any]) throws {
  if let t = try str(body, "title") { r.title = t }
  if let c = try targetCalendar(.reminder, body, nameKey: "list", idKey: "list_id") { r.calendar = c }
  if let v = body["due"] {
    if v is NSNull {
      r.dueDateComponents = nil
    } else if let s = v as? String {
      r.dueDateComponents = try dueComponents(s)
    } else {
      throw bad("due must be a date string or null")
    }
  }
  if let v = body["priority"] {
    guard let p = v as? Int, [0, 1, 5, 9].contains(p) else { throw bad("priority must be 0, 1, 5 or 9") }
    r.priority = p
  }
  if let v = body["completed"] {
    guard let done = v as? Bool else { throw bad("completed must be true or false") }
    r.isCompleted = done
  }
  try applyText(body, "notes") { r.notes = $0 }
  try applyURL(body) { r.url = $0 }
}

func createReminder(_ body: [String: Any]) throws -> Any {
  try requireAccess(.reminder)
  guard let title = try str(body, "title"), !title.isEmpty else { throw bad("title is required") }
  let r = EKReminder(eventStore: store)
  r.calendar = store.defaultCalendarForNewReminders()
  try applyReminderFields(r, body)
  guard r.calendar != nil else { throw bad("no default list; pass list") }
  try store.save(r, commit: true)
  log("created reminder \(r.calendarItemIdentifier) \"\(title)\" in \(r.calendar.title)")
  return reminderJSON(r)
}

func editReminder(_ id: String, _ body: [String: Any]) throws -> Any {
  try requireAccess(.reminder)
  guard let r = store.calendarItem(withIdentifier: id) as? EKReminder else {
    throw HTTPError(status: 404, message: "no reminder \(id)")
  }
  guard r.calendar.allowsContentModifications else { throw bad("\(r.calendar.title) is read-only") }
  try applyReminderFields(r, body)
  try store.save(r, commit: true)
  log("edited reminder \(id) \"\(r.title ?? "")\" fields=\(body.keys.sorted())")
  return reminderJSON(r)
}

func createReminderList(_ body: [String: Any]) throws -> Any {
  try requireAccess(.reminder)
  guard let title = try str(body, "title"), !title.isEmpty else { throw bad("title is required") }
  if store.calendars(for: .reminder).contains(where: { $0.title.lowercased() == title.lowercased() }) {
    throw HTTPError(status: 409, message: "a list named \(title) already exists")
  }
  guard let source = store.defaultCalendarForNewReminders()?.source else { throw bad("no default reminders account") }
  let list = EKCalendar(for: .reminder, eventStore: store)
  list.title = title
  list.source = source
  try store.saveCalendar(list, commit: true)
  log("created reminder list \(list.calendarIdentifier) \"\(title)\" in \(source.title)")
  return calendarJSON(list)
}

// MARK: - Routes

func route(path: String, query: [String: [String]]) throws -> Any {
  func one(_ k: String) -> String? { query[k]?.last }
  func dateParam(_ k: String) throws -> Date? {
    guard let raw = one(k) else { return nil }
    guard let d = parseDate(raw) else { throw bad("bad date for \(k): \(raw)") }
    return d
  }

  switch path {
  case "/health":
    return ["ok": true, "access": access(), "writes_enabled": writeToken() != nil]

  case "/calendars":
    try requireAccess(.event)
    return store.calendars(for: .event).map(calendarJSON)

  case "/reminder-lists":
    try requireAccess(.reminder)
    return store.calendars(for: .reminder).map(calendarJSON)

  case "/events":
    try requireAccess(.event)
    let start = try dateParam("start") ?? Calendar.current.startOfDay(for: Date())
    let end = try dateParam("end") ?? start.addingTimeInterval(7 * 86400)
    guard end > start else { throw bad("end must be after start") }
    guard end.timeIntervalSince(start) <= 366 * 86400 else {
      throw bad("range is limited to one year")
    }
    let cals = try calendars(.event, named: query["calendar"] ?? [])
    let pred = store.predicateForEvents(withStart: start, end: end, calendars: cals)
    return store.events(matching: pred)
      .sorted { $0.startDate < $1.startDate }
      .map(eventJSON)

  case "/reminders":
    try requireAccess(.reminder)
    let cals = try calendars(.reminder, named: query["list"] ?? [])
    let pred: NSPredicate
    switch one("status") ?? "open" {
    case "open":
      pred = store.predicateForIncompleteReminders(
        withDueDateStarting: nil, ending: try dateParam("due_before"), calendars: cals)
    case "completed":
      pred = store.predicateForCompletedReminders(
        withCompletionDateStarting: try dateParam("completed_since") ?? Date().addingTimeInterval(-7 * 86400),
        ending: nil, calendars: cals)
    case "all":
      pred = store.predicateForReminders(in: cals)
    case let other:
      throw bad("status must be open, completed or all, not \(other)")
    }
    let sem = DispatchSemaphore(value: 0)
    var found: [EKReminder] = []
    store.fetchReminders(matching: pred) { rs in
      found = rs ?? []
      sem.signal()
    }
    if sem.wait(timeout: .now() + 30) == .timedOut {
      throw HTTPError(status: 504, message: "Reminders fetch timed out")
    }
    return found.map(reminderJSON)

  default:
    throw HTTPError(status: 404, message: "unknown path \(path)")
  }
}

func writeRoute(method: String, path: String, body: [String: Any]) throws -> Any {
  let parts = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
  switch (method, parts.first, parts.count) {
  case ("POST", "events", 1): return try createEvent(body)
  case ("PATCH", "events", 2): return try editEvent(parts[1], body)
  case ("POST", "reminders", 1): return try createReminder(body)
  case ("PATCH", "reminders", 2): return try editReminder(parts[1], body)
  case ("POST", "reminder-lists", 1): return try createReminderList(body)
  default: throw HTTPError(status: 404, message: "no \(method) route for \(path)")
  }
}

// MARK: - HTTP

let reasons = [200: "OK", 201: "Created", 400: "Bad Request", 401: "Unauthorized", 403: "Forbidden",
               404: "Not Found", 405: "Method Not Allowed", 409: "Conflict", 413: "Payload Too Large",
               415: "Unsupported Media Type", 500: "Internal Server Error",
               503: "Service Unavailable", 504: "Gateway Timeout"]

func respond(_ conn: NWConnection, _ status: Int, _ body: Any) {
  let data = (try? JSONSerialization.data(
    withJSONObject: body, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])) ?? Data("{}".utf8)
  var head = "HTTP/1.1 \(status) \(reasons[status] ?? "")\r\n"
  head += "Content-Type: application/json; charset=utf-8\r\n"
  head += "Content-Length: \(data.count)\r\nConnection: close\r\n\r\n"
  conn.send(content: Data(head.utf8) + data, completion: .contentProcessed { _ in conn.cancel() })
}

func remoteHost(_ conn: NWConnection) -> String {
  guard case let .hostPort(host, _) = conn.endpoint else { return "" }
  var s = "\(host)"
  if let pct = s.firstIndex(of: "%") { s = String(s[..<pct]) }  // strip IPv6 zone
  if s.hasPrefix("::ffff:") { s = String(s.dropFirst(7)) }
  return s
}

let maxBody = 256 * 1024

func dispatch(_ conn: NWConnection, method: String, target: String, headers: [String: String], body: Data) {
  let comps = URLComponents(string: target)
  let path = comps?.path ?? "/"
  do {
    switch method {
    case "GET":
      var query: [String: [String]] = [:]
      for item in comps?.queryItems ?? [] { query[item.name, default: []].append(item.value ?? "") }
      respond(conn, 200, try route(path: path, query: query))

    case "POST", "PATCH":
      guard let token = writeToken() else { throw HTTPError(status: 503, message: "writes disabled: no token file") }
      let auth = headers["authorization"] ?? ""
      guard auth.hasPrefix("Bearer "), constantTimeEqual(String(auth.dropFirst(7)), token) else {
        log("rejected \(method) \(path) from \(remoteHost(conn)): bad token")
        throw HTTPError(status: 401, message: "missing or wrong bearer token")
      }
      guard (headers["content-type"] ?? "").lowercased().hasPrefix("application/json") else {
        throw HTTPError(status: 415, message: "Content-Type must be application/json")
      }
      guard let json = try? JSONSerialization.jsonObject(with: body), let obj = json as? [String: Any] else {
        throw bad("body must be a JSON object")
      }
      respond(conn, method == "POST" ? 201 : 200, try writeRoute(method: method, path: path, body: obj))

    default:
      throw HTTPError(status: 405, message: "\(method) not supported (create and edit only; nothing can be deleted)")
    }
  } catch let e as HTTPError {
    respond(conn, e.status, ["error": e.message])
  } catch {
    respond(conn, 500, ["error": "\(error)"])
  }
}

func handle(_ conn: NWConnection, buffer: Data = Data()) {
  conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { chunk, _, done, err in
    var buf = buffer
    if let chunk = chunk { buf.append(chunk) }
    guard let headerEnd = buf.range(of: Data("\r\n\r\n".utf8)) else {
      if done || err != nil || buf.count > 65536 { conn.cancel() } else { handle(conn, buffer: buf) }
      return
    }
    let headLines = String(decoding: buf[..<headerEnd.lowerBound], as: UTF8.self).components(separatedBy: "\r\n")
    let parts = (headLines.first ?? "").split(separator: " ")
    guard parts.count >= 2 else { return respond(conn, 400, ["error": "bad request line"]) }
    var headers: [String: String] = [:]
    for line in headLines.dropFirst() {
      guard let colon = line.firstIndex(of: ":") else { continue }
      headers[line[..<colon].lowercased()] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
    }
    let length = Int(headers["content-length"] ?? "0") ?? 0
    if length > maxBody { return respond(conn, 413, ["error": "body too large"]) }
    let body = buf[headerEnd.upperBound...]
    if body.count < length && !done && err == nil {
      return handle(conn, buffer: buf)  // keep reading the body
    }
    dispatch(conn, method: String(parts[0]), target: String(parts[1]), headers: headers, body: Data(body.prefix(length)))
  }
}

let params = NWParameters.tcp
params.allowLocalEndpointReuse = true
let listener = try NWListener(using: params, on: port)
listener.newConnectionHandler = { conn in
  let host = remoteHost(conn)
  conn.start(queue: workQueue)
  if !allowed.contains(host) {
    log("refused \(host)")
    return respond(conn, 403, ["error": "client \(host) not allowed"])
  }
  handle(conn)
}
listener.stateUpdateHandler = { state in
  switch state {
  case .ready:
    log("listening on :\(port), allowed: \(allowed.sorted().joined(separator: " ")), writes \(writeToken() != nil ? "enabled" : "disabled")")
  case .failed(let err):
    log("listener failed: \(err)")
    exit(1)  // launchd KeepAlive restarts it
  default: break
  }
}
listener.start(queue: .main)
dispatchMain()
