from pathlib import Path
import sys
from playwright.sync_api import sync_playwright
folder={'capstone':'final-devops-project','monitoring':'session-20-monitoring-gitops'}[sys.argv[1]]
out=Path('evidence')/folder; out.mkdir(parents=True,exist_ok=True)
with sync_playwright() as p:
 browser=p.chromium.launch(channel="chrome")
 page=browser.new_page(viewport={'width':1440,'height':1100})
 page.goto(sys.argv[2],wait_until='networkidle')
 page.wait_for_timeout(3000)
 assert 'nishant' not in page.inner_text('body').lower()
 page.screenshot(path=str(out/'application.png'), full_page=True)
 browser.close()
