"""Collect the license files of the hosted Dart dependencies in this build."""
import json
from pathlib import Path
import subprocess
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
dependencies = json.loads(subprocess.run(["flutter", "pub", "deps", "--json"], cwd=ROOT, check=True, capture_output=True, text=True).stdout)
hosted = [item for item in dependencies["packages"] if item.get("source") == "hosted"]
config_path = ROOT / ".dart_tool/package_config.json"
packages = {item["name"]: item for item in json.loads(config_path.read_text())["packages"]}
notices = ["# Third-party notices\n\nLicenses of hosted Dart packages resolved for this build.\n"]
for dependency in sorted(hosted, key=lambda item: item["name"]):
    uri = packages[dependency["name"]]["rootUri"]
    location = Path(unquote(urlparse(uri).path)) if uri.startswith("file:") else (config_path.parent / uri).resolve()
    license_file = next((location / name for name in ("LICENSE", "LICENSE.md", "LICENSE.txt", "LICENSE.TXT") if (location / name).is_file()), None)
    if license_file is None:
        raise SystemExit(f"Missing dependency license: {dependency['name']}")
    notices.append(f"\n## {dependency['name']} {dependency['version']}\n\n```text\n{license_file.read_text(errors='replace')}\n```\n")
(ROOT / "THIRD_PARTY_NOTICES.md").write_text("\n".join(notices))
print(f"Collected {len(hosted)} dependency licenses")
