"""Real database/HTTP check, including contention on the same product row."""
import concurrent.futures
import json
import os
import urllib.error
import urllib.request
import uuid

base = os.environ.get("BASE_URL", "http://127.0.0.1:8000")

def request(path, payload=None, method=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(base + path, data=data, method=method, headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            body = r.read()
            return r.status, json.loads(body) if body else None
    except urllib.error.HTTPError as e:
        return e.code, json.load(e)

assert request('/ready')[0] == 200
code, product = request('/api/products', {'sku': 'CI-' + uuid.uuid4().hex[:10].upper(), 'name': 'Concurrent dispatch check', 'unit_price_cents': 12345})
assert code == 201
pid = product['id']
assert request('/api/movements', {'product_id': pid, 'delta': 2, 'reason': 'Initial receipt'})[0] == 201

def withdraw(_):
    return request('/api/movements', {'product_id': pid, 'delta': -1, 'reason': 'Concurrent dispatch'})[0]

with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
    statuses = list(pool.map(withdraw, range(6)))
assert statuses.count(201) == 2 and statuses.count(409) == 4, statuses
assert request(f'/api/products/{pid}')[1]['quantity'] == 0
assert request(f'/api/products/{pid}', method='DELETE')[0] == 204
assert request(f'/api/products/{pid}')[0] == 404
print('PASS: migrations ready, create/read/archive, concurrent dispatch, no overselling.')
