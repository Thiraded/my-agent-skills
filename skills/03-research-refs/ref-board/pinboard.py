#!/usr/bin/env python3
"""Pinterest reference board builder (headless Chrome, no login, read-only).

Usage:
  python pinboard.py OUT.html "Section title=query one|query two" "Other section=query" ...
  python pinboard.py OUT.html --file sections.json     # {"Section": ["q1","q2"], ...}

Each query is searched on Pinterest in a headless Chrome (virtual-time render), the pins are
parsed (pin URL, 736x image URL, alt) and written to ONE self-contained HTML board with a sticky
nav. Images are hotlinked and link back to the pin page. Nothing is downloaded or posted.
Env: CHROME=path to chrome.exe (auto-detected), PER=max pins per query (default 12).
"""
import html, json, os, re, subprocess, sys, tempfile, urllib.parse
from html.parser import HTMLParser

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) "
      "Chrome/130.0 Safari/537.36")


def find_chrome():
    for p in (os.environ.get("CHROME"), r"C:\Program Files\Google\Chrome\Application\chrome.exe",
              r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
              "/usr/bin/google-chrome", "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"):
        if p and os.path.exists(p):
            return p
    sys.exit("Chrome not found; set CHROME=path")


class Pins(HTMLParser):
    # Pinterest's rendered DOM has no /pin/ anchors (pins are role=button) and images carry
    # srcset, not src, with alt="Pin". So we key on the image URL and link to the original.
    def __init__(self):
        super().__init__()
        self.pins = []

    def handle_starttag(self, tag, a):
        if tag != "img":
            return
        a = dict(a)
        src = (a.get("src") or "") + " " + (a.get("srcset") or "")
        m = re.search(r"https://i\.pinimg\.com/(?:\d+x\d*|originals)/([0-9a-f]{2}/[0-9a-f]{2}/[0-9a-f]{2}/[0-9a-f]+\.\w+)", src)
        if not m:
            return
        tail = m.group(1)
        alt = a.get("alt", "")
        self.pins.append({"pin": "https://i.pinimg.com/originals/" + tail, "img": "https://i.pinimg.com/736x/" + tail,
                          "alt": "" if alt == "Pin" else alt})


def search(chrome, q, per):
    url = "https://www.pinterest.com/search/pins/?q=" + urllib.parse.quote(q)
    r = subprocess.run([chrome, "--headless=new", "--disable-gpu", "--no-sandbox", "--virtual-time-budget=15000",
                        f"--user-agent={UA}", "--dump-dom", url], capture_output=True, timeout=120)
    p = Pins()
    p.feed(r.stdout.decode("utf-8", "replace"))
    seen, out = set(), []
    for x in p.pins:
        if x["img"] not in seen:
            seen.add(x["img"]); out.append(x)
    return out[:per]


CSS = """body{margin:0;background:#0b0b10;color:#eee;font:15px system-ui,sans-serif}nav{position:sticky;top:0;background:#000d;backdrop-filter:blur(6px);padding:8px 16px;display:flex;gap:14px;flex-wrap:wrap;z-index:9}
nav a{color:#e9c46a;text-decoration:none}main{padding:16px 24px;max-width:1500px;margin:auto}h2 small{color:#888;font-weight:400;font-size:12px}
.grid{columns:5 200px;column-gap:10px}figure{margin:0 0 10px;break-inside:avoid;background:#222}figure img{width:100%;display:block}figcaption{font-size:10px;color:#999;padding:2px 6px}
.q{color:#9cf;font-size:12px;margin:0 0 8px}footer{color:#777;font-size:12px;padding:30px 0}"""


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    out, args = sys.argv[1], sys.argv[2:]
    if args[0] == "--file":
        sections = json.load(open(args[1], encoding="utf-8"))
    else:
        sections = {a.split("=", 1)[0]: a.split("=", 1)[1].split("|") for a in args}
    per, chrome = int(os.environ.get("PER", 12)), find_chrome()
    nav, parts, total = [], [], 0
    for i, (title, qs) in enumerate(sections.items()):
        seen, figs = set(), []
        for q in qs:
            try:
                pins = search(chrome, q, per)
            except Exception as e:
                print("ERR", q, e, file=sys.stderr); pins = []
            print(f"{title} | {q}: {len(pins)}", flush=True)
            for x in pins:
                if x["img"] in seen: continue
                seen.add(x["img"])
                figs.append(f'<figure><a href="{x["pin"]}" target="_blank"><img loading="lazy" referrerpolicy="no-referrer" '
                            f'src="{html.escape(x["img"])}" alt="{html.escape(x["alt"])}"></a>'
                            f'<figcaption>{html.escape(x["alt"][:70])}</figcaption></figure>')
        total += len(figs)
        parts.append(f'<section id="s{i}"><h2>{html.escape(title)} <small>{len(figs)} pins</small></h2>'
                     f'<p class="q">{html.escape(" · ".join(qs))}</p><div class="grid">{"".join(figs)}</div></section>')
        nav.append(f'<a href="#s{i}">{html.escape(title)}</a>')
    open(out, "w", encoding="utf-8").write(
        f'<!doctype html><meta charset="utf-8"><title>Ref board</title><style>{CSS}</style><nav>{"".join(nav)}</nav>'
        f'<main><h1>Ref board</h1>{"".join(parts)}<footer>Images from Pinterest, owned by their creators. Inspiration only; click an image for the source pin.</footer></main>')
    print("total pins", total, "->", out)


if __name__ == "__main__":
    main()
