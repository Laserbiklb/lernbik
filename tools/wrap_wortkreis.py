"""Turns wortkreis/wortkreis.html (artifact page, no <html> skeleton) into web/wortkreis/index.html."""
import pathlib
src = pathlib.Path("wortkreis/wortkreis.html").read_text(encoding="utf8")
out = pathlib.Path("web/wortkreis/index.html")
out.parent.mkdir(parents=True, exist_ok=True)
head = ('<!doctype html><html lang="ru"><head><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'
        '<style>:root{color-scheme:light;padding-top:env(safe-area-inset-top);padding-bottom:env(safe-area-inset-bottom)}'
        'body{margin:0;font:14px system-ui,-apple-system,Segoe UI,Roboto,sans-serif}img{max-width:100%}[hidden]{display:none!important}</style>'
        '</head><body>')
out.write_text(head + src + "</body></html>", encoding="utf8")
print("wrote", out, len(src))
