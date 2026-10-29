// notes-mirror: one-way copy of the Obsidian vault into an "Obsidian" folder
// in iCloud Notes, so Siri and Spotlight can search it on every Apple device.
//
// Usage: notes-mirror <rsync> <cmark-gfm> <rsync-source> <ssh-key>
//
// Each run:
//   1. rsyncs the vault's .md files from nix-nuc (the always-current LiveSync
//      copy) into ~/Library/Application Support/notes-mirror/vault. If nix-nuc
//      is unreachable, it mirrors the last copy it has.
//   2. Renders each changed note to HTML (cmark-gfm, after turning Obsidian
//      syntax into plain Markdown) and creates or updates its note through
//      AppleScript. Subfolders mirror the vault's folders.
//   3. Deletes mirror notes whose vault note is gone (they go to Notes'
//      Recently Deleted). It only ever touches notes it created itself.
//
// State (path -> note id + content hash) lives in state.json next to the vault
// copy, so unchanged notes cost nothing. Edits made in Notes are overwritten
// the next time the vault note changes.

import CryptoKit
import Foundation

let rendererVersion = "2"  // bump to re-render every note
let rootFolder = "Obsidian"
let account = "iCloud"

let args = CommandLine.arguments
guard args.count == 5 else {
  FileHandle.standardError.write("usage: notes-mirror <rsync> <cmark-gfm> <rsync-source> <ssh-key>\n".data(using: .utf8)!)
  exit(2)
}
let (rsync, cmark, source, sshKey) = (args[1], args[2], args[3], args[4])

let fm = FileManager.default
let support = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/notes-mirror")
let vault = support.appendingPathComponent("vault")
let stateURL = support.appendingPathComponent("state.json")

func log(_ msg: String) {
  print("\(ISO8601DateFormatter().string(from: Date())) \(msg)")
  fflush(stdout)
}

@discardableResult
func run(_ exe: String, _ arguments: [String], stdin: String? = nil) -> (status: Int32, out: String, err: String) {
  let p = Process()
  p.executableURL = URL(fileURLWithPath: exe)
  p.arguments = arguments
  let outPipe = Pipe(), errPipe = Pipe(), inPipe = Pipe()
  p.standardOutput = outPipe
  p.standardError = errPipe
  if stdin != nil { p.standardInput = inPipe }
  do { try p.run() } catch { return (127, "", "\(error)") }
  if let s = stdin {
    inPipe.fileHandleForWriting.write(s.data(using: .utf8)!)
    try? inPipe.fileHandleForWriting.close()
  }
  let out = outPipe.fileHandleForReading.readDataToEndOfFile()
  let err = errPipe.fileHandleForReading.readDataToEndOfFile()
  p.waitUntilExit()
  return (p.terminationStatus, String(decoding: out, as: UTF8.self), String(decoding: err, as: UTF8.self))
}

// MARK: - 1. Pull the vault

try fm.createDirectory(at: vault, withIntermediateDirectories: true)
let pull = run(rsync, [
  "-a", "--delete", "--prune-empty-dirs",
  "--exclude=.obsidian/", "--exclude=.trash/", "--exclude=.git/",
  "--include=*/", "--include=*.md", "--exclude=*",
  "-e", "/usr/bin/ssh -i \(sshKey) -o BatchMode=yes -o IdentitiesOnly=yes -o ConnectTimeout=10",
  source.hasSuffix("/") ? source : source + "/",
  vault.path + "/",
])
if pull.status != 0 {
  log("rsync from \(source) failed (exit \(pull.status)); mirroring the last copy. \(pull.err.trimmingCharacters(in: .whitespacesAndNewlines))")
}

// MARK: - 2. Render

func sha(_ s: String) -> String {
  SHA256.hash(data: Data((rendererVersion + s).utf8)).map { String(format: "%02x", $0) }.joined()
}

func replacing(_ s: String, _ pattern: String, _ template: String, options: NSRegularExpression.Options = []) -> String {
  let re = try! NSRegularExpression(pattern: pattern, options: options)
  return re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: template)
}

func escapeHTML(_ s: String) -> String {
  s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
    .replacingOccurrences(of: ">", with: "&gt;")
}

// Obsidian-flavored Markdown -> plain Markdown cmark-gfm understands.
func plainMarkdown(_ raw: String, title: String) -> String {
  var s = raw.replacingOccurrences(of: "\r\n", with: "\n")
  if s.hasPrefix("---\n"), let end = s.range(of: "\n---\n", range: s.index(s.startIndex, offsetBy: 4)..<s.endIndex) {
    s = String(s[end.upperBound...])  // YAML frontmatter
  }
  s = replacing(s, #"%%[\s\S]*?%%"#, "")  // comments, incl. the Kanban settings block
  s = replacing(s, #"!\[\[[^\]]*\]\]"#, "")  // embeds
  s = replacing(s, #"\[\[[^\]|]*\|([^\]]*)\]\]"#, "$1")  // [[target|alias]]
  s = replacing(s, #"\[\[([^\]#]*)#([^\]]*)\]\]"#, "$1 › $2")  // [[note#heading]]
  s = replacing(s, #"\[\[([^\]]*)\]\]"#, "$1")  // [[note]]
  // Notes drops HTML checkboxes, so tasks become characters.
  s = replacing(s, #"^(\s*[-*+] )\[ \] "#, "$1☐ ", options: .anchorsMatchLines)
  s = replacing(s, #"^(\s*[-*+] )\[[^ \]]\] "#, "$1☑ ", options: .anchorsMatchLines)
  // The note title comes from the file name; drop a matching leading H1.
  let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
  if let first = trimmed.split(separator: "\n", maxSplits: 1).first,
     first.trimmingCharacters(in: .whitespaces).lowercased() == "# \(title)".lowercased() {
    s = String(trimmed.dropFirst(first.count))
  }
  return s
}

func renderHTML(_ raw: String, path: String, title: String) -> String? {
  let md = plainMarkdown(raw, title: title)
  let r = run(cmark, ["--unsafe", "-e", "table", "-e", "strikethrough", "-e", "autolink"], stdin: md)
  guard r.status == 0 else {
    log("cmark-gfm failed on \(path): \(r.err)")
    return nil
  }
  // Notes titles a note with its first line: a note's own H1 wins over the file name.
  let ownH1 = md.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("# ")
  let heading = ownH1 ? "" : "<h1>\(escapeHTML(title))</h1>\n"
  return "\(heading)\(r.out)\n<p><i>Mirrored from Obsidian: \(escapeHTML(path)). Edits here are overwritten.</i></p>"
}

// MARK: - 3. Notes (AppleScript)

func asString(_ s: String) -> String {
  "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
}

struct NotesError: Error { let message: String }

@discardableResult
func appleScript(_ body: String) throws -> String {
  let source = "tell application \"Notes\"\n\(body)\nend tell"
  var err: NSDictionary?
  guard let script = NSAppleScript(source: source) else { throw NotesError(message: "script did not compile") }
  let result = script.executeAndReturnError(&err)
  if let err = err {
    throw NotesError(message: "\(err[NSAppleScript.errorNumber] ?? "?"): \(err[NSAppleScript.errorMessage] ?? "?")")
  }
  return result.stringValue ?? ""
}

// AppleScript lines that leave `f` pointing at Obsidian/<dirs>, creating folders as needed.
func folderChain(_ dirs: [String]) -> String {
  var lines = [
    "set acc to account \(asString(account))",
    "if not (exists folder \(asString(rootFolder)) of acc) then make new folder at acc with properties {name:\(asString(rootFolder))}",
    "set f to folder \(asString(rootFolder)) of acc",
  ]
  for d in dirs {
    lines.append("if not (exists folder \(asString(d)) of f) then make new folder at f with properties {name:\(asString(d))}")
    lines.append("set f to folder \(asString(d)) of f")
  }
  return lines.joined(separator: "\n")
}

func noteExists(_ id: String) -> Bool {
  (try? appleScript("return (exists note id \(asString(id))) as text")) == "true"
}

func createNote(_ html: String, dirs: [String]) throws -> String {
  try appleScript("""
    \(folderChain(dirs))
    set n to make new note at f with properties {body:\(asString(html))}
    return id of n
    """)
}

func updateNote(_ id: String, _ html: String) throws {
  try appleScript("set body of note id \(asString(id)) to \(asString(html))")
}

func deleteNote(_ id: String) throws {
  try appleScript("if exists note id \(asString(id)) then delete note id \(asString(id))")
}

// MARK: - Sync

struct Entry: Codable {
  var id: String
  var hash: String
}

var state: [String: Entry] = (try? JSONDecoder().decode([String: Entry].self, from: Data(contentsOf: stateURL))) ?? [:]
func saveState() {
  if let data = try? JSONEncoder().encode(state) { try? data.write(to: stateURL, options: .atomic) }
}

var paths: [String] = []
if let e = fm.enumerator(at: vault, includingPropertiesForKeys: nil) {
  for case let url as URL in e where url.pathExtension == "md" {
    paths.append(String(url.path.dropFirst(vault.path.count + 1)))
  }
}
paths.sort()

// An empty vault copy means the first pull failed, not that every note was deleted.
if paths.isEmpty {
  log("no notes in \(vault.path); nothing to mirror")
  exit(pull.status == 0 ? 0 : 1)
}

var created = 0, updated = 0, deleted = 0, failed = 0
do {
  for path in paths {
    guard let raw = try? String(contentsOf: vault.appendingPathComponent(path), encoding: .utf8) else { continue }
    let hash = sha(raw)
    if let entry = state[path], entry.hash == hash, noteExists(entry.id) { continue }
    var dirs = path.split(separator: "/").map(String.init)
    let title = String(dirs.removeLast().dropLast(3))
    guard let html = renderHTML(raw, path: path, title: title) else { failed += 1; continue }
    if let entry = state[path], noteExists(entry.id) {
      try updateNote(entry.id, html)
      updated += 1
    } else {
      state[path] = Entry(id: try createNote(html, dirs: dirs), hash: hash)
      created += 1
    }
    state[path]?.hash = hash
    saveState()
  }

  let current = Set(paths)
  for (path, entry) in state where !current.contains(path) {
    try deleteNote(entry.id)
    state[path] = nil
    deleted += 1
    saveState()
  }
} catch let e as NotesError {
  log("Notes error: \(e.message) (if -1743, allow notes-mirror under Privacy & Security > Automation > Notes)")
  exit(1)
}

if created + updated + deleted + failed > 0 {
  log("synced \(paths.count) notes: \(created) created, \(updated) updated, \(deleted) removed, \(failed) failed")
}
