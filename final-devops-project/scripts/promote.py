"""Change only image tags; leave operator-managed ingress/secrets settings intact."""
from pathlib import Path
import re
import sys


def promote(path, sha):
    if not re.fullmatch(r"[a-f0-9]{40}", sha):
        raise ValueError("Expected a full lowercase Git commit SHA")
    content, count = re.subn(r'(?m)^    tag: .+$', f'    tag: "{sha}"', path.read_text())
    if count != 2:
        raise ValueError("Expected exactly the backend and frontend image tags")
    path.write_text(content)


if __name__ == "__main__":
    promote(Path(__file__).resolve().parents[1] / "helm/stockroom/values-gitops.yaml", sys.argv[1])
