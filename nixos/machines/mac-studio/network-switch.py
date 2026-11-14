"""Headless client for the RealHD PSW24-25G-MG switch web UI (Realtek "Hydra" CGI API).

Needs NETWORK_SWITCH_USER / NETWORK_SWITCH_PASSWORD in the environment (NETWORK_SWITCH_HOST
optional). From the homelab-claude workspace, run it through withenv:
  bin/withenv 'switchctl vlans'                    # every port's mode + VLAN membership
  bin/withenv 'switchctl macs [MGE9|vlan=50]'      # MAC address table
  bin/withenv 'switchctl port-vlans MGE2 1UP,50T'  # set membership (running config only)
  bin/withenv 'switchctl save'                     # write running -> startup

Friendly commands:
  vlans                 Defined VLANs, then each port's mode, PVID and membership
  macs [port|vlan=N]    Dynamic MAC table, optionally filtered
  port-vlans <port> <spec>
                        Replace a port's VLAN membership. <spec> is comma-separated
                        <vid><flags>: U untagged, T tagged, F forbidden, P PVID,
                        e.g. 1UP,2T,3T (trunk/access ports need exactly one U).
                        Prints before/after. Not persistent until `save`.

Raw commands:
  get <cmd> [k=v ...]   GET cgi/get.cgi?cmd=<cmd>, print JSON
  set <cmd> k=v ...     POST cgi/set.cgi?cmd=<cmd> with the UI's form encoding
  save                  Save running config to startup (else lost on reboot)
  cmds [filter]         List every get/set cmd the UI knows (from js/url.js)
  pages                 List UI pages (menu tree) and their HTML paths
  fields <html-path>    Show form field names and set cmds a UI page uses (fields built
                        by JS helpers may be missing: confirm by reading the page's JS)
  logout

How it works: login RSA-encrypts the password with the modulus from home_login,
posts it to home_loginAuth, then polls home_loginStatus. The session is bound to
the client IP (no cookie). Set bodies are a JSON-quoted string
"_ds=1&<urlencoded form>&_de=1", exactly what the UI's formDataGet sends.
"""
import base64, json, os, re, secrets, sys, time, urllib.parse, urllib.request

HOST = os.environ.get("NETWORK_SWITCH_HOST", "@defaultHost@").rstrip("/")
if not HOST.startswith("http"):
    HOST = "http://" + HOST


def _ts():
    return str(int(time.time() * 1000))


def _open(path, data=None):
    req = urllib.request.Request(f"{HOST}/{path}", data=data,
                                 headers={"Content-Type": "application/json"} if data else {})
    with urllib.request.urlopen(req, timeout=15) as r:
        return r.read().decode("utf-8", "replace")


def _json(text):
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return {"raw": text}


def _rsa(msg, mod_hex):
    n = int(mod_hex, 16)
    k = (n.bit_length() + 7) // 8
    m = msg.encode()
    ps = bytes(secrets.randbelow(255) + 1 for _ in range(k - len(m) - 3))  # PKCS#1 v1.5 type 2
    c = pow(int.from_bytes(b"\x00\x02" + ps + b"\x00" + m, "big"), 65537, n)
    return base64.b64encode(c.to_bytes(k, "big")).decode()


def _form(pairs):
    return json.dumps("_ds=1&" + (urllib.parse.urlencode(pairs) or "empty=1") + "&_de=1").encode()


def raw_get(cmd, params=()):
    q = urllib.parse.urlencode([("cmd", cmd), *params, ("dummy", _ts())])
    return _json(_open(f"cgi/get.cgi?{q}"))


def login():
    user, pw = os.environ.get("NETWORK_SWITCH_USER"), os.environ.get("NETWORK_SWITCH_PASSWORD")
    if not user or not pw:
        sys.exit("NETWORK_SWITCH_USER / NETWORK_SWITCH_PASSWORD not set (run via bin/withenv)")
    mod = raw_get("home_login")["data"]["modulus"]
    _open(f"cgi/set.cgi?cmd=home_loginAuth&dummy={_ts()}",
          _form([("username", user), ("password", _rsa(pw, mod))]))
    time.sleep(1)
    for _ in range(15):
        st = raw_get("home_loginStatus").get("data", {})
        if st.get("status") == "ok":
            return
        if st.get("status") == "fail":
            sys.exit(f"login failed: {st.get('failReason')}")
        time.sleep(1)
    sys.exit("login timed out")


def authed(fn):
    r = fn()
    if isinstance(r, dict) and r.get("logout"):
        login()
        r = fn()
    return r


MODES = {0: "hybrid", 1: "access", 2: "trunk", 3: "tunnel"}


def port_names():
    """Index -> name (MGE1..24, TE1..2, LAG1..8); the CGI addresses ports by index."""
    return [p["port"] for p in authed(lambda: raw_get("home_main"))["data"]["ports"]]


def kv(args):
    out = []
    for a in args:
        k, sep, v = a.partition("=")
        if not sep:
            sys.exit(f"expected key=value, got {a!r}")
        out.append((k, v))
    return out


def main(argv):
    if not argv or argv[0] in ("-h", "--help"):
        print(__doc__)
        return
    c, rest = argv[0], argv[1:]
    if c == "get":
        r = authed(lambda: raw_get(rest[0], kv(rest[1:])))
    elif c == "set":
        body = _form(kv(rest[1:]))
        r = authed(lambda: _json(_open(f"cgi/set.cgi?cmd={rest[0]}&dummy={_ts()}", body)))
    elif c == "vlans":
        names = port_names()
        conf = authed(lambda: raw_get("vlan_conf"))["data"]
        print("VLANs:", ", ".join(v["name"] for v in conf["vlans"]))
        mem = raw_get("vlan_membership")["data"]["ports"]
        vp = raw_get("vlan_port")["data"]["ports"]
        for i, (m, p) in enumerate(zip(mem, vp)):
            oper = "" if m["operVlans"] == m["adminVlans"] else f"  (oper: {m['operVlans']})"
            print(f"{names[i]:6} {MODES.get(m['mode'], m['mode']):7} pvid={p['pvid']:<5} {m['adminVlans']}{oper}")
        return
    elif c == "macs":
        ents = authed(lambda: raw_get("mac_dynamic"))["data"]["entries"]
        f = rest[0] if rest else ""
        for e in ents:
            if not f or e["port"] == f.upper() or f == f"vlan={e['vlan']}":
                print(f"{e['port']:6} vlan={e['vlan']:<5} {e['macAddr']}")
        return
    elif c == "port-vlans":
        if len(rest) != 2:
            sys.exit("usage: port-vlans <port> <spec, e.g. 1UP,2T,50T>")
        names = port_names()
        port = rest[0].upper()
        if port not in names:
            sys.exit(f"unknown port {port}; ports: {' '.join(names)}")
        idx = names.index(port)
        spec = [s.strip().upper() for s in rest[1].split(",") if s.strip()]
        for s in spec:
            if not re.fullmatch(r"\d{1,4}[UTF]P?", s):
                sys.exit(f"bad entry {s!r}: want <vid>U|T|F with optional P")
        before = raw_get("vlan_membership")["data"]["ports"][idx]
        print(f"before: {port} {before['adminVlans']}")
        r = _json(_open(f"cgi/set.cgi?cmd=vlan_membershipEdit&dummy={_ts()}",
                        _form([("port", str(idx))] + [("A", s) for s in spec])))
        after = raw_get("vlan_membership")["data"]["ports"][idx]
        print(f"result: {json.dumps(r)}")
        print(f"after:  {port} {after['adminVlans']}  (running config; run `save` to persist)")
        return
    elif c == "save":
        r = authed(lambda: _json(_open(f"cgi/set.cgi?cmd=home_save&dummy={_ts()}")))
    elif c == "logout":
        r = _json(_open(f"cgi/set.cgi?cmd=home_logout&dummy={_ts()}"))
    elif c == "cmds":
        js = _open("js/url.js")
        for name, path in re.findall(r"var url_(\w+)\s*=\s*'[./]*(cgi/\S+?)';", js):
            line = f"{path.split('cmd=')[1]:32} {path.split('.cgi')[0].split('/')[-1]:4} ({name})"
            if not rest or rest[0].lower() in line.lower():
                print(line)
        return
    elif c == "pages":
        d = authed(lambda: raw_get("home_main")).get("data", {})
        def walk(nodes, depth):
            for n in nodes:
                name = re.sub(r"lang\('menu','(\w+)'\)", r"\1", n.get("name", ""))
                print("  " * depth + name + (f"  ->  {n['url']}" if n.get("url") else ""))
                walk(n.get("leaves", []), depth + 1)
        walk(d.get("menuTree", []), 0)
        return
    elif c == "fields":
        html = _open(rest[0].lstrip("/"))
        names = sorted(set(re.findall(r"""(?:name|id)=["']?([\w\-]+)""", html)))
        sets = sorted(set(re.findall(r"url\('?(set_\w+)'?\)|url_(set_\w+)", html)))
        print("fields:", " ".join(names))
        print("set urls:", " ".join(a or b for a, b in sets))
        return
    else:
        sys.exit(f"unknown command {c!r}; see --help")
    print(json.dumps(r, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main(sys.argv[1:])
