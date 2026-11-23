"""decision: append-only log of key homelab decisions, for future agents.

SQLite with an FTS5 index, in @logDir@ (override with DECISION_LOG_DIR).
Entries are never edited or deleted: a reversal or correction is a new entry
with --supersedes. Every write regenerates decisions.md next to the database,
a read-only copy for reading in Finder.

Tags are a controlled vocabulary. Each has a description and aliases; search
matches aliases too, so an entry tagged home-assistant is found by "hass".
New tags are refused when they look like an existing tag or alias.

Also serves the Claude Code hooks for homelab-claude (`decision hook ...`).
See decision-log.nix.
"""

import argparse
import datetime as dt
import difflib
import json
import os
import re
import sqlite3
import sys
import time
from pathlib import Path

LOG_DIR = Path(os.environ.get("DECISION_LOG_DIR") or "@logDir@").expanduser()
DB = LOG_DIR / "decisions.db"
MD = LOG_DIR / "decisions.md"
HOOK_STATE = Path.home() / "Library/Caches/decision-log"
ACTORS = ("cooper", "claude")
NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

SCHEMA = """
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
CREATE TABLE entries (
  id         INTEGER PRIMARY KEY,
  ts         TEXT NOT NULL,  -- when it happened, local time with offset
  ts_utc     TEXT NOT NULL,  -- same instant in UTC, for sorting and filters
  logged_at  TEXT NOT NULL,
  actor      TEXT NOT NULL CHECK (actor IN ('cooper', 'claude')),
  project    TEXT,
  summary    TEXT NOT NULL,
  why        TEXT,
  actions    TEXT,
  undo       TEXT,
  refs       TEXT,           -- one per line
  supersedes INTEGER REFERENCES entries(id)
);
CREATE INDEX entries_ts ON entries(ts_utc);
CREATE INDEX entries_supersedes ON entries(supersedes);
CREATE TABLE tags (
  name        TEXT PRIMARY KEY,
  description TEXT NOT NULL,
  created_at  TEXT NOT NULL
);
CREATE TABLE tag_aliases (
  alias TEXT PRIMARY KEY,
  tag   TEXT NOT NULL REFERENCES tags(name)
);
CREATE TABLE entry_tags (
  entry_id INTEGER NOT NULL REFERENCES entries(id),
  tag      TEXT NOT NULL REFERENCES tags(name),
  PRIMARY KEY (entry_id, tag)
);
CREATE VIRTUAL TABLE entries_fts USING fts5(
  summary, why, actions, undo, refs, project, tagtext,
  tokenize = 'porter unicode61'
);
CREATE TRIGGER entries_no_update BEFORE UPDATE ON entries
  BEGIN SELECT RAISE(ABORT, 'the decision log is append-only'); END;
CREATE TRIGGER entries_no_delete BEFORE DELETE ON entries
  BEGIN SELECT RAISE(ABORT, 'the decision log is append-only'); END;
"""

# Starting vocabulary, written once when the database is created.
SEED_TAGS = [
    ("network", "LAN design, routing, IP addressing, general connectivity", ["networking", "lan", "routing"]),
    ("unifi", "UniFi gateway and controller settings, UniFi devices", ["ubiquiti", "gateway", "udm"]),
    ("firewall", "Firewall policies and zones, port forwards, IPS", ["port-forward", "ips", "traffic-rule"]),
    ("vlan", "VLAN layout, subnets, per-port VLAN membership", ["subnet"]),
    ("wifi", "WLANs and SSIDs, access points, wireless settings", ["wlan", "ssid", "wireless", "access-point"]),
    ("dns", "DNS resolution, AdGuard, NetShield, local DNS records", ["adguard", "netshield", "resolver"]),
    ("vpn", "Proton VPN and other VPN tunnels (not Tailscale)", ["proton", "wireguard"]),
    ("tailscale", "Tailscale tailnet, ACLs, exit nodes, MagicDNS", ["tailnet"]),
    ("switch", "RealHD managed switch config (switchctl)", ["network-switch", "switchctl", "realhd"]),
    ("home-assistant", "Home Assistant / HAOS config, integrations, entities, add-ons", ["hass", "haos", "ha"]),
    ("ha-automation", "Home Assistant automations, scripts and scenes", ["automation", "script", "scene"]),
    ("zigbee", "Zigbee / ZHA devices and mesh", ["zha"]),
    ("esphome", "ESPHome devices and firmware", ["esp", "esp32"]),
    ("nix", "Nix flake, NixOS and nix-darwin config in ~/Nix", ["nixos", "nix-darwin", "flake", "home-manager"]),
    ("secrets", "Secret storage and distribution (agenix, NAS secrets share)", ["agenix", "credentials"]),
    ("truenas", "TrueNAS host config, apps, shares, users", ["nas"]),
    ("zfs", "ZFS pools, datasets, snapshots, replication", ["pool", "dataset", "snapshot"]),
    ("backup", "Backup jobs, targets, retention", ["rsync"]),
    ("plex", "Plex Media Server, libraries, transcoding, sharing", ["tautulli"]),
    ("arr-stack", "Sonarr, Radarr, Prowlarr, Overseerr, download clients",
     ["sonarr", "radarr", "prowlarr", "overseerr", "arr", "download-client"]),
    ("llm", "Local LLMs: LM Studio heavy/light models and schedules", ["lmstudio", "lm-studio", "local-llm"]),
    ("stubert", "Stubert assistant: crons, skills, config on nix-nuc", []),
    ("obsidian", "Obsidian vault, wiki notes, LiveSync, Kanban boards", ["vault", "wiki", "kanban", "notes"]),
    ("claude", "Claude Code setup: hooks, skills, memory, remote control, this log",
     ["claude-code", "hooks", "agents", "decision-log"]),
    ("mac", "This M3 Max MacBook Pro (mac-studio) and its launchd jobs", ["mac-studio", "macbook", "launchd"]),
    ("nix-nuc", "The nix-nuc server", ["nuc"]),
    ("raspberry-pi", "Raspberry Pi hosts (fortress-pi, adguard-pi, ...)", ["pi", "fortress-pi", "adguard-pi"]),
    ("windows-pc", "Windows 11 gaming PC (lewis-pc)", ["lewis-pc", "gaming-pc"]),
    ("photo", "Photo workflow, DAS volumes, photo backups", ["photography", "lightroom", "das"]),
    ("hardware", "Physical hardware: purchases, moves, cabling, drives", ["cabling", "drives", "rack"]),
    ("calendar", "calendar-bridge, Apple Calendar and Reminders", ["calendar-bridge", "reminders"]),
]

RULES = """\
## Decision log

Cooper keeps an append-only log of key decisions, so future agents can see what was decided, when,
by whom, and exactly what was done. Use the `decision` CLI (SQLite in
~/Developer/homelab-claude/decision-log/; decisions.md there is a generated read-only copy).

Log an entry right after any key decision or change, yours or Cooper's, about the homelab or its
projects: network, UniFi, firewall, VLAN, WiFi or switch changes; Home Assistant / HAOS attributes,
integrations or automations; Nix config; service settings; storage; hardware moves; and choices
between options (note the rejected alternatives in --why). One entry per decision. Skip routine
reads and one-off device toggles that change nothing lasting.

- Before tagging, check `decision tags`; reuse a tag or alias. Create one with
  --new-tag 'name=description' only when nothing covers the topic.
- `decision add "<one-line summary>" --by cooper|claude --tag <t> [--tag ...] [--project <p>]
  [--why ...] [--actions ...] [--undo ...] [--ref ...] [--at 'YYYY-MM-DD HH:MM'] [--supersedes N]`
  --by is who made the call (Cooper approving your proposal counts as cooper). --actions holds the
  exact commands or API calls. --at only when it happened earlier than now.
- Before revisiting a past choice, check history: `decision search <words> [--tag t] [--since date]`,
  `decision show N`, `decision recent`.
- Never edit the database or decisions.md by hand. Corrections are new entries with --supersedes.
"""


# ---------------------------------------------------------------- utilities

def die(msg):
    print(f"decision: {msg}", file=sys.stderr)
    sys.exit(1)


def now_local():
    return dt.datetime.now().astimezone().replace(microsecond=0)


def utc(t):
    return t.astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_time(s, end_of_day=False):
    s = s.strip()
    if re.fullmatch(r"\d{1,2}:\d{2}", s):
        s = f"{now_local():%Y-%m-%d} {s}"
    try:
        t = dt.datetime.fromisoformat(s)
    except ValueError:
        die(f"can't parse time {s!r}; use YYYY-MM-DD, 'YYYY-MM-DD HH:MM' or HH:MM")
    if end_of_day and re.fullmatch(r"\d{4}-\d{2}-\d{2}", s):
        t += dt.timedelta(days=1, seconds=-1)
    return t.astimezone() if t.tzinfo is None else t


def norm(term):
    """Comparison key: case, punctuation and a plural 's' don't matter."""
    s = re.sub(r"[^a-z0-9]", "", term.lower())
    return s[:-1] if len(s) > 3 and s.endswith("s") else s


def initials(term):
    parts = [p for p in re.split(r"[-_ ]+", term.lower()) if p]
    return "".join(p[0] for p in parts) if len(parts) > 1 else None


def similar(a, b):
    na, nb = norm(a), norm(b)
    if na == nb or difflib.SequenceMatcher(None, na, nb).ratio() >= 0.8:
        return True
    if min(len(na), len(nb)) >= 4 and (na in nb or nb in na):
        return True
    return initials(a) == nb or initials(b) == na


def one_line(s, width=None):
    s = " ".join(s.split())
    return s if width is None or len(s) <= width else s[: width - 1] + "…"


# ---------------------------------------------------------------- database

def connect():
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    fresh = not DB.exists()
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys = ON")
    if fresh:
        with con:
            con.executescript(SCHEMA)
            con.execute("INSERT INTO meta VALUES ('schema_version', '1')")
            stamp = now_local().isoformat()
            for name, desc, aliases in SEED_TAGS:
                con.execute("INSERT INTO tags VALUES (?, ?, ?)", (name, desc, stamp))
                con.executemany("INSERT INTO tag_aliases VALUES (?, ?)", [(a, name) for a in aliases])
        export(con)
    return con


def vocab(con):
    """Every tag name and alias, as (term, tag) pairs."""
    rows = [(r["name"], r["name"]) for r in con.execute("SELECT name FROM tags")]
    rows += [(r["alias"], r["tag"]) for r in con.execute("SELECT alias, tag FROM tag_aliases")]
    return rows


def resolve_tag(con, term):
    key = norm(term)
    for t, tag in vocab(con):
        if norm(t) == key:
            return tag
    return None


def tag_suggestions(con, term):
    v = vocab(con)
    close = difflib.get_close_matches(term.lower(), [t for t, _ in v], n=5, cutoff=0.6)
    close += [t for t, _ in v if similar(term, t) and t not in close]
    tags = dict.fromkeys(dict(v)[t] for t in close)
    return list(tags)[:5]


def check_new_name(kind, name, existing, force):
    if not NAME_RE.match(name):
        die(f"{kind} {name!r} must be lowercase kebab-case, like 'home-assistant'")
    if force:
        return
    hits = sorted({owner for term, owner in existing if similar(name, term)})
    if hits:
        die(f"new {kind} {name!r} looks like existing {kind} {', '.join(hits)}. "
            f"Use that instead, or pass --force if it's a genuinely different topic.")


def create_tag(con, name, desc, aliases, force):
    if not desc.strip():
        die(f"new tag {name!r} needs a description")
    if (owner := resolve_tag(con, name)):
        die(f"tag {name!r} already exists as {owner!r}; use it")
    check_new_name("tag", name, vocab(con), force)
    con.execute("INSERT INTO tags VALUES (?, ?, ?)", (name, desc.strip(), now_local().isoformat()))
    for a in aliases:
        add_alias(con, name, a)


def add_alias(con, tag, alias):
    alias = alias.strip().lower()
    if not alias:
        die("empty alias")
    if (owner := resolve_tag(con, alias)):
        if owner == tag:
            return
        die(f"alias {alias!r} already belongs to tag {owner!r}")
    con.execute("INSERT INTO tag_aliases VALUES (?, ?)", (alias, tag))


def entry_tags(con, eid):
    return [r["tag"] for r in con.execute("SELECT tag FROM entry_tags WHERE entry_id = ? ORDER BY tag", (eid,))]


def tagtext(con, tags):
    words = list(tags)
    for t in tags:
        words += [r["alias"] for r in con.execute("SELECT alias FROM tag_aliases WHERE tag = ?", (t,))]
    return " ".join(words)


def index_entry(con, e):
    con.execute("DELETE FROM entries_fts WHERE rowid = ?", (e["id"],))
    con.execute(
        "INSERT INTO entries_fts (rowid, summary, why, actions, undo, refs, project, tagtext)"
        " VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        (e["id"], e["summary"], e["why"], e["actions"], e["undo"], e["refs"], e["project"],
         tagtext(con, entry_tags(con, e["id"]))))


def reindex(con):
    for e in con.execute("SELECT * FROM entries").fetchall():
        index_entry(con, e)


def get_entry(con, eid):
    e = con.execute("SELECT * FROM entries WHERE id = ?", (eid,)).fetchone()
    if not e:
        die(f"no entry #{eid}")
    return e


def superseded_by(con, eid):
    return [r["id"] for r in con.execute("SELECT id FROM entries WHERE supersedes = ? ORDER BY id", (eid,))]


# ---------------------------------------------------------------- output

def stamp(e):
    t = dt.datetime.fromisoformat(e["ts"])
    return t.strftime("%Y-%m-%d %H:%M:%S ") + t.strftime("%z")[:3] + ":" + t.strftime("%z")[3:]


def as_dict(con, e):
    d = dict(e)
    d["tags"] = entry_tags(con, e["id"])
    d["superseded_by"] = superseded_by(con, e["id"])
    return d


def fmt_entry(con, e, brief=False):
    tags = entry_tags(con, e["id"])
    later = superseded_by(con, e["id"])
    if brief:
        mark = f" (superseded by #{', #'.join(map(str, later))})" if later else ""
        return f"#{e['id']} {stamp(e)[:16]} [{', '.join(tags)}] {e['summary']}{mark}"
    head = f"#{e['id']} · {stamp(e)} · by {e['actor']}"
    if e["project"]:
        head += f" · project: {e['project']}"
    lines = [head, f"    {e['summary']}", f"    tags:    {', '.join(tags)}"]
    for field in ("why", "actions", "undo", "refs"):
        if e[field]:
            body = e[field].splitlines()
            lines.append(f"    {field + ':':<8} {body[0]}")
            lines += [f"             {line}" for line in body[1:]]
    links = []
    if e["supersedes"]:
        links.append(f"supersedes #{e['supersedes']}")
    if later:
        links.append(f"superseded by #{', #'.join(map(str, later))}")
    if links:
        lines.append("    " + " · ".join(links))
    return "\n".join(lines)


def print_entries(con, rows, args):
    if getattr(args, "json", False):
        print(json.dumps([as_dict(con, e) for e in rows], indent=2))
    elif not rows:
        print("No matching entries.")
    else:
        sep = "\n" if getattr(args, "brief", False) else "\n\n"
        print(sep.join(fmt_entry(con, e, getattr(args, "brief", False)) for e in rows))


def md_block(label, text, code=False):
    if code:
        return [f"- **{label}:**", "  ```", *[f"  {l}" for l in text.splitlines()], "  ```"]
    first, *rest = text.splitlines()
    return [f"- **{label}:** {first}", *[f"  {l}" for l in rest]]


def export(con):
    """Regenerate decisions.md, newest first, as a read-only file."""
    out = ["# Decision log", "",
           f"*Generated from decisions.db by `decision` at {now_local():%Y-%m-%d %H:%M}. "
           "Read-only copy: edits here are overwritten. Add entries with `decision add`.*"]
    day = None
    for e in con.execute("SELECT * FROM entries ORDER BY ts_utc DESC, id DESC"):
        s = stamp(e)
        if s[:10] != day:
            day = s[:10]
            out += ["", f"## {day}"]
        out += ["", f"### #{e['id']} · {s[11:16]} {s[20:]} · {e['summary']}", ""]
        meta = f"- **By:** {e['actor']}"
        if e["project"]:
            meta += f" · **Project:** {e['project']}"
        meta += f" · **Tags:** {', '.join(entry_tags(con, e['id']))}"
        out.append(meta)
        if e["why"]:
            out += md_block("Why", e["why"])
        if e["actions"]:
            out += md_block("Actions", e["actions"], code=True)
        if e["undo"]:
            out += md_block("Undo", e["undo"])
        if e["refs"]:
            out += md_block("Refs", e["refs"])
        links = []
        if e["supersedes"]:
            links.append(f"**Supersedes:** #{e['supersedes']}")
        if (later := superseded_by(con, e["id"])):
            links.append(f"**Superseded by:** #{', #'.join(map(str, later))}")
        if links:
            out.append("- " + " · ".join(links))
    tmp = MD.with_name(".decisions.md.tmp")
    tmp.write_text("\n".join(out) + "\n")
    tmp.chmod(0o444)
    os.replace(tmp, MD)


# ---------------------------------------------------------------- commands

def cmd_add(con, args):
    summary = args.summary.strip()
    if not summary or "\n" in summary:
        die("the summary must be one non-empty line; put detail in --why")
    at = parse_time(args.at) if args.at else now_local()
    if at > now_local() + dt.timedelta(minutes=5):
        die(f"--at {args.at!r} is in the future")
    with con:
        tags = []
        for spec in args.new_tag:
            name, sep, desc = spec.partition("=")
            if not sep:
                die(f"--new-tag takes 'name=description', got {spec!r}")
            create_tag(con, name.strip(), desc, [], args.force)
            tags.append(name.strip())
        for t in args.tag:
            tag = resolve_tag(con, t)
            if not tag:
                hint = tag_suggestions(con, t)
                die(f"unknown tag {t!r}." + (f" Close: {', '.join(hint)}." if hint else "")
                    + " See `decision tags`, or create it with --new-tag 'name=description'.")
            tags.append(tag)
        tags = list(dict.fromkeys(tags))
        if not tags:
            die("at least one --tag (or --new-tag) is required")
        project = args.project.strip().lower() if args.project else None
        if project:
            known = [r["project"] for r in con.execute("SELECT DISTINCT project FROM entries WHERE project IS NOT NULL")]
            if project not in known:
                check_new_name("project", project, [(p, p) for p in known], args.force)
        if args.supersedes:
            get_entry(con, args.supersedes)
        cur = con.execute(
            "INSERT INTO entries (ts, ts_utc, logged_at, actor, project, summary, why, actions, undo, refs, supersedes)"
            " VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (at.isoformat(), utc(at), now_local().isoformat(), args.by, project, summary,
             (args.why or "").strip() or None, (args.actions or "").strip() or None,
             (args.undo or "").strip() or None, "\n".join(r.strip() for r in args.ref) or None,
             args.supersedes))
        eid = cur.lastrowid
        con.executemany("INSERT INTO entry_tags VALUES (?, ?)", [(eid, t) for t in tags])
        index_entry(con, get_entry(con, eid))
    export(con)
    print(f"Logged #{eid}\n")
    print(fmt_entry(con, get_entry(con, eid)))


def fts_query(con, text, all_terms):
    """Each word is a phrase; a word naming a tag or alias also matches that tag."""
    phrases = []
    for word in text.split():
        toks = re.findall(r"\w+", word)
        if not toks:
            continue
        phrase = '"' + " ".join(toks) + '"'
        tag = resolve_tag(con, word)
        if tag:
            phrase = f'({phrase} OR tagtext : "{" ".join(tag.split("-"))}")'
        phrases.append(phrase)
    return (" AND " if all_terms else " OR ").join(phrases)


def cmd_search(con, args):
    where, params = [], []
    for t in args.tag:
        tag = resolve_tag(con, t)
        if not tag:
            hint = tag_suggestions(con, t)
            die(f"unknown tag {t!r}." + (f" Close: {', '.join(hint)}." if hint else ""))
        where.append("e.id IN (SELECT entry_id FROM entry_tags WHERE tag = ?)")
        params.append(tag)
    if args.project:
        where.append("e.project = ?")
        params.append(args.project.lower())
    if args.by:
        where.append("e.actor = ?")
        params.append(args.by)
    if args.since:
        where.append("e.ts_utc >= ?")
        params.append(utc(parse_time(args.since)))
    if args.until:
        where.append("e.ts_utc <= ?")
        params.append(utc(parse_time(args.until, end_of_day=True)))
    query = fts_query(con, " ".join(args.text), args.all)
    if query:
        sql = ("SELECT e.* FROM entries_fts JOIN entries e ON e.id = entries_fts.rowid"
               " WHERE entries_fts MATCH ?" + "".join(f" AND {w}" for w in where) +
               " ORDER BY bm25(entries_fts, 10, 3, 2, 1, 2, 3, 5), e.ts_utc DESC LIMIT ?")
        params = [query, *params]
    else:
        sql = ("SELECT e.* FROM entries e" + (" WHERE " + " AND ".join(where) if where else "") +
               " ORDER BY e.ts_utc DESC, e.id DESC LIMIT ?")
    print_entries(con, con.execute(sql, [*params, args.limit]).fetchall(), args)


def cmd_show(con, args):
    out = []
    for eid in args.id:
        e = get_entry(con, eid)
        chain, cur = [eid], e
        while cur["supersedes"]:
            chain.insert(0, cur["supersedes"])
            cur = get_entry(con, cur["supersedes"])
        nxt = superseded_by(con, eid)
        while nxt:
            chain.append(nxt[0])
            nxt = superseded_by(con, nxt[0])
        if args.json:
            out.append(as_dict(con, e))
            continue
        text = fmt_entry(con, e)
        if len(chain) > 1:
            text += "\n    history: " + " → ".join(f"#{i}" + (" (this)" if i == eid else "") for i in chain)
        out.append(text)
    print(json.dumps(out, indent=2) if args.json else "\n\n".join(out))


def cmd_recent(con, args):
    rows = con.execute("SELECT * FROM entries ORDER BY ts_utc DESC, id DESC LIMIT ?", (args.n,)).fetchall()
    print_entries(con, rows, args)


def tag_rows(con):
    return con.execute(
        "SELECT t.name, t.description,"
        " (SELECT group_concat(alias, ', ') FROM (SELECT alias FROM tag_aliases WHERE tag = t.name ORDER BY alias)) AS aliases,"
        " (SELECT count(*) FROM entry_tags WHERE tag = t.name) AS uses"
        " FROM tags t ORDER BY t.name").fetchall()


def cmd_tags(con, args):
    rows = tag_rows(con)
    if args.json:
        print(json.dumps([dict(r) for r in rows], indent=2))
        return
    width = max(len(r["name"]) for r in rows)
    for r in rows:
        print(f"{r['name']:<{width}}  ({r['uses']})  {r['description']}")
        if r["aliases"]:
            print(f"{'':<{width}}       aliases: {r['aliases']}")


def cmd_tag_new(con, args):
    with con:
        create_tag(con, args.name, args.description, args.alias, args.force)
    print(f"Created tag {args.name!r}")


def cmd_tag_alias(con, args):
    tag = resolve_tag(con, args.tag)
    if not tag:
        die(f"unknown tag {args.tag!r}")
    with con:
        for a in args.alias:
            add_alias(con, tag, a)
        reindex(con)
    print(f"Aliases for {tag!r}: " + ", ".join(
        r["alias"] for r in con.execute("SELECT alias FROM tag_aliases WHERE tag = ? ORDER BY alias", (tag,))))


def cmd_projects(con, args):
    rows = con.execute("SELECT project, count(*) AS n, max(ts) AS last FROM entries"
                       " WHERE project IS NOT NULL GROUP BY project ORDER BY last DESC").fetchall()
    if not rows:
        print("No projects yet.")
    for r in rows:
        print(f"{r['project']}  ({r['n']} entries, last {r['last'][:10]})")


def cmd_export(con, args):
    export(con)
    print(f"Wrote {MD}")


def cmd_context(con, args):
    print(RULES)
    rows = con.execute("SELECT * FROM entries ORDER BY ts_utc DESC, id DESC LIMIT 10").fetchall()
    if rows:
        print("Most recent entries:")
        print("\n".join(fmt_entry(con, e, brief=True) for e in rows))
    else:
        print("The log has no entries yet.")
    print("\nTags (see `decision tags` for descriptions and aliases): "
          + ", ".join(r["name"] for r in tag_rows(con)))
    projects = [r["project"] for r in con.execute(
        "SELECT project FROM entries WHERE project IS NOT NULL GROUP BY project ORDER BY max(ts_utc) DESC")]
    if projects:
        print("Projects: " + ", ".join(projects))


# ---------------------------------------------------------------- hooks

# Bash commands that change state somewhere. Matches are only a prompt to log;
# Claude decides whether any of them was a key decision.
STATEFUL = [re.compile(p, re.I) for p in (
    r"\bcurl\b[^|;&]*?(?:-X\s*|--request[ =])['\"]?(?:POST|PUT|PATCH|DELETE)\b",
    r"\bcurl\b[^|;&]*?\s(?:-d|--data(?:-raw|-binary|-urlencode)?|--json|-F|--form)[\s=]",
    r"\bswitchctl\s+(?:set|port-vlans|save|restore)\b",
    r"\b(?:darwin|nixos)-rebuild\s+(?:switch|boot|test|activate)\b",
    r"\bupdate-remote\b",
    r"\bzfs\s+(?:create|destroy|set|inherit|rollback|snapshot|rename|promote|clone|receive|recv)\b",
    r"\bzpool\s+(?:create|destroy|add|remove|attach|detach|replace|set|export|import|upgrade)\b",
    r"\bha\s+(?:core|supervisor|host|os|addons?|apps?|backups?|network|dns)\s+"
    r"(?:restart|reboot|shutdown|update|install|uninstall|start|stop|rebuild|options|new|restore|remove)\b",
    r"\bsystemctl\s+(?:--user\s+)?(?:restart|stop|start|enable|disable|mask|unmask|reload)\b",
    r"(?:^|[;&|'\"]\s*)(?:sudo\s+)?(?:reboot|shutdown|poweroff)\b",
    r"\bdocker(?:\s+compose)?\s+(?:restart|stop|start|rm|up|down|kill|pull)\b",
    r"\blaunchctl\s+(?:kickstart|bootout|bootstrap|load|unload|enable|disable)\b",
    r"\bwinget\s+(?:install|uninstall|upgrade)\b",
    r"\b(?:Set|New|Remove|Enable|Disable|Restart|Stop|Start)-[A-Z][A-Za-z]+",
    r"[\"']type[\"']\s*:\s*[\"'][a-z_/]*(?:create|update|delete|remove|configure|promote)[\"']",
)]
LOGGED = re.compile(r"\bdecision\s+add\b")
EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
WATCHED = (str(Path.home() / "Nix") + "/", str(Path.home() / "Developer/homelab-claude/CLAUDE.md"))


def tool_uses(line):
    try:
        rec = json.loads(line)
    except ValueError:
        return
    if rec.get("type") != "assistant":
        return
    content = (rec.get("message") or {}).get("content")
    if isinstance(content, list):
        for c in content:
            if isinstance(c, dict) and c.get("type") == "tool_use":
                yield c.get("name"), c.get("input") or {}


def hook_stop(payload):
    """Block the stop once if state changed since the last `decision add`.

    Only transcript lines new since the previous Stop are checked, so each
    change prompts at most once."""
    session = re.sub(r"[^A-Za-z0-9_-]", "", payload.get("session_id", "")) or "unknown"
    transcript = Path(payload.get("transcript_path") or "")
    if not transcript.is_file():
        return
    HOOK_STATE.mkdir(parents=True, exist_ok=True)
    state = HOOK_STATE / f"{session}.offset"
    try:
        offset = int(state.read_text())
    except (OSError, ValueError):
        offset = 0
    with transcript.open("rb") as f:
        f.seek(0, os.SEEK_END)
        if f.tell() < offset:
            offset = 0
        f.seek(offset)
        data = f.read()
    # Leave a partly written last line for next time.
    end = data.rfind(b"\n") + 1
    state.write_text(str(offset + end))
    if payload.get("stop_hook_active"):
        return

    pending = []
    for line in data[:end].decode("utf-8", "replace").splitlines():
        for name, inp in tool_uses(line):
            if name == "Bash":
                cmd = inp.get("command") or ""
                if LOGGED.search(cmd):
                    pending = []
                elif any(p.search(cmd) for p in STATEFUL):
                    pending.append("ran: " + one_line(cmd, 160))
            elif name in EDIT_TOOLS:
                path = inp.get("file_path") or inp.get("notebook_path") or ""
                if path.startswith(WATCHED):
                    pending.append(f"{name.lower()}: {path}")
    if not pending:
        return
    pending = list(dict.fromkeys(pending))
    listed = "\n".join(f"- {p}" for p in pending[:8])
    if len(pending) > 8:
        listed += f"\n- …and {len(pending) - 8} more"
    print(json.dumps({"decision": "block", "reason":
        "Decision log check: these changed state since the last `decision add`:\n" + listed +
        "\n\nIf any of them was a key decision or change (see the decision log rules), log it now with "
        "`decision add` (check `decision tags` first), then finish. If none was, just finish; "
        "this check won't repeat for these."}))


def hook_session_start(payload):
    HOOK_STATE.mkdir(parents=True, exist_ok=True)
    cutoff = time.time() - 14 * 86400
    for f in HOOK_STATE.glob("*.offset"):
        if f.stat().st_mtime < cutoff:
            f.unlink(missing_ok=True)
    cmd_context(connect(), None)


def cmd_hook(args):
    try:
        payload = json.loads(sys.stdin.read() or "{}")
    except ValueError:
        payload = {}
    try:
        {"stop": hook_stop, "session-start": hook_session_start}[args.event](payload)
    except Exception as exc:  # A broken hook must never block Claude.
        print(f"decision hook {args.event} failed: {exc}", file=sys.stderr)


# ---------------------------------------------------------------- main

def main():
    p = argparse.ArgumentParser(prog="decision", description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True, metavar="command")

    a = sub.add_parser("add", help="log a decision")
    a.add_argument("summary", help="one line: what was decided or changed")
    a.add_argument("--by", required=True, choices=ACTORS, help="who made the call")
    a.add_argument("--tag", action="append", default=[], help="existing tag or alias (repeatable)")
    a.add_argument("--new-tag", action="append", default=[], metavar="NAME=DESC",
                   help="create a tag and use it (repeatable)")
    a.add_argument("--project", help="kebab-case project name (see `decision projects`)")
    a.add_argument("--why", help="reasoning, constraints, rejected alternatives")
    a.add_argument("--actions", help="exact commands, API calls, files or settings changed")
    a.add_argument("--undo", help="how to reverse it")
    a.add_argument("--ref", action="append", default=[], help="file, commit, entity id, URL (repeatable)")
    a.add_argument("--at", help="when it happened, if earlier than now: 'YYYY-MM-DD HH:MM' or HH:MM")
    a.add_argument("--supersedes", type=int, metavar="ID", help="entry this reverses or corrects")
    a.add_argument("--force", action="store_true", help="allow a new tag/project that looks like an existing one")

    s = sub.add_parser("search", help="full-text search (tags and aliases included)")
    s.add_argument("text", nargs="*", help="words to find; any word matches unless --all")
    s.add_argument("--all", action="store_true", help="require every word")
    s.add_argument("--tag", action="append", default=[], help="only entries with this tag (repeatable)")
    s.add_argument("--project")
    s.add_argument("--by", choices=ACTORS)
    s.add_argument("--since", help="date or datetime")
    s.add_argument("--until", help="date or datetime")
    s.add_argument("--limit", type=int, default=10)
    s.add_argument("--brief", action="store_true", help="one line per entry")
    s.add_argument("--json", action="store_true")

    sh = sub.add_parser("show", help="show entries in full, with their supersede history")
    sh.add_argument("id", type=int, nargs="+")
    sh.add_argument("--json", action="store_true")

    r = sub.add_parser("recent", help="latest entries")
    r.add_argument("n", type=int, nargs="?", default=10)
    r.add_argument("--brief", action="store_true")
    r.add_argument("--json", action="store_true")

    t = sub.add_parser("tags", help="list tags with descriptions, aliases and use counts")
    t.add_argument("--json", action="store_true")

    tn = sub.add_parser("tag-new", help="create a tag without logging an entry")
    tn.add_argument("name")
    tn.add_argument("description")
    tn.add_argument("--alias", action="append", default=[])
    tn.add_argument("--force", action="store_true")

    ta = sub.add_parser("tag-alias", help="add aliases to a tag")
    ta.add_argument("tag")
    ta.add_argument("alias", nargs="+")

    sub.add_parser("projects", help="list projects")
    sub.add_parser("export", help="regenerate decisions.md")
    sub.add_parser("context", help="rules plus recent entries (what the SessionStart hook shows)")

    h = sub.add_parser("hook", help="Claude Code hook entry point")
    h.add_argument("event", choices=["stop", "session-start"])

    args = p.parse_args()
    if args.cmd == "hook":
        return cmd_hook(args)
    con = connect()
    {"add": cmd_add, "search": cmd_search, "show": cmd_show, "recent": cmd_recent, "tags": cmd_tags,
     "tag-new": cmd_tag_new, "tag-alias": cmd_tag_alias, "projects": cmd_projects,
     "export": cmd_export, "context": cmd_context}[args.cmd](con, args)


if __name__ == "__main__":
    main()
