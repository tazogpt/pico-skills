#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALL_DIR="$(pwd)"
REPO_ROOT="$(git -C "${CALL_DIR}" rev-parse --show-toplevel 2>/dev/null || true)"

if [[ -z "${REPO_ROOT}" ]]; then
  echo "ERROR: run uninstall.sh from inside the target Git repository" >&2
  exit 1
fi

SOURCE_GIT_ROOT="$(git -C "${SOURCE_ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ "${REPO_ROOT}" == "${SOURCE_GIT_ROOT}" ]]; then
  echo "ERROR: run from the target project, not the workflow source repository" >&2
  exit 1
fi

rm -rf "${REPO_ROOT}/.ai/workflow/skills"
rm -rf "${REPO_ROOT}/.ai/workflow/communication"
rm -f "${REPO_ROOT}/.ai/workflow/BOOTSTRAP.md"

python3 - "${REPO_ROOT}/AGENTS.md" "${REPO_ROOT}/CLAUDE.md" <<'PY'
from pathlib import Path
import sys

start = "<!-- agent-workflow-bootstrap:start -->"
end = "<!-- agent-workflow-bootstrap:end -->"

for raw in sys.argv[1:]:
    path = Path(raw)
    if not path.exists():
        continue
    text = path.read_text(encoding="utf-8")
    while start in text and end in text:
        before, rest = text.split(start, 1)
        _, after = rest.split(end, 1)
        text = (before.rstrip() + "\n" + after.lstrip("\n")).strip()
        if text:
            text += "\n"
    path.write_text(text, encoding="utf-8")
PY

echo "removed managed workflow files and bootstrap blocks"
echo "preserved CONFIG.md, PRINCIPLES.md, STATE.md, and ARCHI.md"
