"""Screenshot real captured logs, retaining exact output plus run/commit metadata."""
from pathlib import Path
import html, json, os, re
from playwright.sync_api import sync_playwright
root=Path('evidence')
with sync_playwright() as p:
 browser=p.chromium.launch(channel="chrome")
 page=browser.new_page(viewport={'width':1440,'height':1000}, device_scale_factor=1)
 for log in sorted(root.glob('*/validation.log')):
  text=log.read_text()
  if re.search(r'nishant|24bcs10314', text, re.I):
   raise RuntimeError(f'Source identity found in fresh evidence: {log}')
  text=re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', text)
  metadata={'student':'Mayank Gupta','roll_number':'24BCS10220','repository':os.environ['GITHUB_REPOSITORY'],'commit':os.environ['GITHUB_SHA'],'run_url':f"https://github.com/{os.environ['GITHUB_REPOSITORY']}/actions/runs/{os.environ['GITHUB_RUN_ID']}",'section':log.parent.name,'kind':'Screenshot of actual CI command log; scope limited to commands shown'}
  (log.parent/'validation.json').write_text(json.dumps(metadata,indent=2)+'\n')
  # Paginate long logs, preserving every line across images.
  lines=text.splitlines()
  chunks=[lines[i:i+55] for i in range(0,len(lines),55)] or [[]]
  for i,chunk in enumerate(chunks):
   page.set_content('<html><head><style>body{background:#0b1220;color:#e3eaf4;margin:0;padding:32px;font:17px monospace}h1{font:26px sans-serif;color:#71e0c1}p{font:16px sans-serif;color:#c1d0e7}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:15px;line-height:1.55}</style></head><body><h1>Mayank Gupta · 24BCS10220</h1><p>'+html.escape(log.parent.name)+f' · Actual GitHub Actions output · Page {i+1}/{len(chunks)}</p><p>'+html.escape(metadata['run_url'])+'</p><pre>'+html.escape('\n'.join(chunk))+'</pre></body></html>')
   path=log.parent/('validation.png' if i==0 else f'validation-{i+1:02}.png')
   page.screenshot(path=str(path),full_page=True)
 browser.close()
