"""Verify the app adapter and SQLite persistence in an isolated local sandbox."""
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]


def verify():
    binary = os.environ.get("MOBILELAB_BIN") or shutil.which("mobilelab")
    if not binary:
        raise SystemExit("Install MobileLab 1.1.0 and set MOBILELAB_BIN or add it to PATH.")
    binary = str(Path(binary).resolve())
    with tempfile.TemporaryDirectory(prefix="pocket_mobilelab_") as directory:
        sandbox = Path(directory)
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            port = listener.getsockname()[1]
        config, count = re.subn(r"(?m)^(\s*port:\s*)\d+\s*$", rf"\g<1>{port}", (ROOT / "mobilelab.yaml").read_text(), count=1)
        if count != 1:
            raise SystemExit("Unable to configure the isolated sandbox port.")
        (sandbox / "mobilelab.yaml").write_text(config)
        shutil.copytree(ROOT / "mobilelab", sandbox / "mobilelab", ignore=shutil.ignore_patterns("*.db", "*.db-*", "*.log", "state.json", ".state.json"))
        base = f"http://127.0.0.1:{port}"

        def request(path, method="GET", document=None):
            req = urllib.request.Request(base + path, method=method, data=json.dumps(document).encode() if document is not None else None, headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=2) as response:
                body = response.read()
                return json.loads(body) if body else None

        def start(log):
            process = subprocess.Popen([binary, "start", "--headless"], cwd=sandbox, stdout=log, stderr=subprocess.STDOUT)
            for _ in range(100):
                if process.poll() is not None:
                    raise RuntimeError("MobileLab exited before becoming ready.")
                try:
                    request("/api/tasks")
                    return process
                except OSError:
                    time.sleep(0.1)
            process.terminate()
            process.wait(timeout=10)
            raise RuntimeError("MobileLab readiness timed out.")

        def stop(process):
            if process.poll() is None:
                process.terminate()
            process.wait(timeout=10)

        with open(sandbox / "integration.log", "w+") as log:
            process = start(log)
            try:
                subprocess.run(["flutter", "test", "tool/integration/mobilelab_repository_test.dart", f"--dart-define=MOBILELAB_TEST_URL={base}"], cwd=ROOT, check=True)
                document = {"id": "persistence-" + uuid.uuid4().hex, "title": "Survives restart", "priority": 0, "completed": False, "createdAt": "2026-11-17T00:00:00.000Z"}
                request("/api/tasks/" + document["id"], "PUT", document)
                stop(process)
                process = start(log)
                restored = request("/api/tasks/" + document["id"])
                if restored != document:
                    raise RuntimeError("The SQLite document did not survive the service restart.")
                request("/api/tasks/" + document["id"], "DELETE")
                print("MobileLab CRUD and SQLite persistence after restart: passed")
            finally:
                stop(process)


if __name__ == "__main__":
    verify()
