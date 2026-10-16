#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
import json, os, urllib.request, urllib.error
base = os.getenv('BASE_URL', 'http://localhost:8000').rstrip('/')
items = [
 ('KB-101','Mechanical keyboard','Peripherals',450000,8,32),
 ('MS-102','Wireless mouse','Peripherals',180000,10,6),
 ('MN-201','27-inch monitor','Displays',2200000,4,12),
 ('HB-301','USB-C hub','Accessories',320000,6,0),
 ('CB-401','Braided USB-C cable','Accessories',65000,20,85),
 ('ST-501','Laptop stand','Workspace',240000,5,4),
]
def post(path, payload):
 req=urllib.request.Request(base+path, data=json.dumps(payload).encode(),headers={'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=15) as r:return json.load(r)
for sku,name,category,price,reorder,quantity in items:
 try:
  product=post('/api/products',dict(sku=sku,name=name,category=category,unit_price_cents=price,reorder_level=reorder))
 except urllib.error.HTTPError as e:
  if e.code==409:
   print('Already present:',sku);continue
  raise
 if quantity:post('/api/movements',dict(product_id=product['id'],delta=quantity,reason='Opening stock — sample inventory'))
 print('Created:',sku)
PY
