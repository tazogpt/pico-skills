#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALL_DIR="$(pwd)"
DRY_RUN="false"

usage() {
  cat <<'EOF'
Usage:
  Run from the target Git repository:
    ./.ai/vendor/agent-workflow-skills/install.sh [--dry-run]

Options:
  --dry-run   Print the target repository and planned changes
  -h, --help  Show this help

This installer never installs into a global home-directory skill path.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

REPO_ROOT="$(git -C "${CALL_DIR}" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${REPO_ROOT}" ]]; then
  echo "ERROR: run install.sh from inside the target Git repository" >&2
  exit 1
fi

SOURCE_GIT_ROOT="$(git -C "${SOURCE_ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ "${REPO_ROOT}" == "${SOURCE_GIT_ROOT}" ]]; then
  echo "ERROR: current Git repository is the workflow source repository." >&2
  echo "Run this script from the target project root, for example:" >&2
  echo "  ./.ai/vendor/agent-workflow-skills/install.sh" >&2
  exit 1
fi

WORKFLOW_DIR="${REPO_ROOT}/.ai/workflow"
MEMORY_DIR="${REPO_ROOT}/.ai/memory"

if [[ "${DRY_RUN}" == "true" ]]; then
  cat <<EOF
target repository: ${REPO_ROOT}
install:
  ${WORKFLOW_DIR}/skills
  ${WORKFLOW_DIR}/communication
  ${WORKFLOW_DIR}/BOOTSTRAP.md
create if absent:
  ${WORKFLOW_DIR}/CONFIG.md
  ${WORKFLOW_DIR}/PRINCIPLES.md
  ${WORKFLOW_DIR}/STATE.md
  ${MEMORY_DIR}/ARCHI.md
patch managed bootstrap block:
  ${REPO_ROOT}/AGENTS.md
  ${REPO_ROOT}/CLAUDE.md
EOF
  exit 0
fi

mkdir -p "${WORKFLOW_DIR}" "${MEMORY_DIR}"

replace_tree() {
  local source="$1"
  local destination="$2"
  rm -rf "${destination}"
  mkdir -p "$(dirname "${destination}")"
  cp -a "${source}" "${destination}"
}

install_if_absent() {
  local source="$1"
  local destination="$2"
  if [[ -e "${destination}" ]]; then
    echo "preserved: ${destination#${REPO_ROOT}/}"
  else
    mkdir -p "$(dirname "${destination}")"
    cp "${source}" "${destination}"
    echo "created: ${destination#${REPO_ROOT}/}"
  fi
}

replace_tree "${SOURCE_ROOT}/skills" "${WORKFLOW_DIR}/skills"
replace_tree "${SOURCE_ROOT}/communication" "${WORKFLOW_DIR}/communication"
cp "${SOURCE_ROOT}/templates/BOOTSTRAP.md" "${WORKFLOW_DIR}/BOOTSTRAP.md"

install_if_absent "${SOURCE_ROOT}/templates/CONFIG.md" "${WORKFLOW_DIR}/CONFIG.md"
install_if_absent "${SOURCE_ROOT}/templates/PRINCIPLES.md" "${WORKFLOW_DIR}/PRINCIPLES.md"
install_if_absent "${SOURCE_ROOT}/templates/STATE.md" "${WORKFLOW_DIR}/STATE.md"
install_if_absent "${SOURCE_ROOT}/templates/ARCHI.md" "${MEMORY_DIR}/ARCHI.md"

START_MARKER="<!-- agent-workflow-bootstrap:start -->"
END_MARKER="<!-- agent-workflow-bootstrap:end -->"

patch_instruction_file() {
  local file="$1"
  touch "${file}"

  if grep -Fq "${START_MARKER}" "${file}"; then
    echo "preserved bootstrap: ${file#${REPO_ROOT}/}"
    return
  fi

  if [[ -s "${file}" ]]; then
    printf '\n' >> "${file}"
  fi

  cat >> "${file}" <<'EOF'
<!-- agent-workflow-bootstrap:start -->
사용자 메시지가 `워크플로워`로 시작하면 즉시 `.ai/workflow/BOOTSTRAP.md`를 읽고 따른다.
사용자에게 스킬 로드, pane 확인, 역할 매핑, 역할 전환, 준비 확인 명령을 추가로 요구하지 않는다.
<!-- agent-workflow-bootstrap:end -->
EOF

  echo "patched bootstrap: ${file#${REPO_ROOT}/}"
}

patch_instruction_file "${REPO_ROOT}/AGENTS.md"
patch_instruction_file "${REPO_ROOT}/CLAUDE.md"

echo "installed repository-local workflow: ${REPO_ROOT}"
echo "invoke with only five role assignments under '워크플로워'"
