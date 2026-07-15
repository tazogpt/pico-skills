#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS="${ROOT}/skills"

required_roles=(
  agent-workflow-orchestrator
  agent-workflow-architect
  agent-workflow-plan-reviewer
  agent-workflow-implementer
  agent-workflow-implementation-reviewer
)

required_support=(
  agent-workflow-tdd
  agent-workflow-interview
)

failed=0
declare -A seen=()

for name in "${required_roles[@]}" "${required_support[@]}"; do
  file="${SKILLS}/${name}/SKILL.md"
  if [[ ! -f "${file}" ]]; then
    echo "FAIL: missing ${file}"
    failed=1
    continue
  fi

  declared="$(awk '
    NR == 1 && $0 == "---" {f=1; next}
    f && $0 == "---" {exit}
    f && /^name:[[:space:]]*/ {sub(/^name:[[:space:]]*/, ""); print; exit}
  ' "${file}")"

  description="$(awk '
    NR == 1 && $0 == "---" {f=1; next}
    f && $0 == "---" {exit}
    f && /^description:[[:space:]]*/ {sub(/^description:[[:space:]]*/, ""); print; exit}
  ' "${file}")"

  [[ "${declared}" == "${name}" ]] || {
    echo "FAIL: ${name} declares '${declared}'"
    failed=1
  }

  [[ -n "${description}" ]] || {
    echo "FAIL: ${name} missing description"
    failed=1
  }

  [[ -z "${seen[${declared}]:-}" ]] || {
    echo "FAIL: duplicate ${declared}"
    failed=1
  }
  seen["${declared}"]=1

  echo "checked: ${name}"
done

for file in \
  templates/BOOTSTRAP.md \
  templates/CONFIG.md \
  templates/PRINCIPLES.md \
  templates/STATE.md \
  templates/ARCHI.md \
  communication/protocol.md \
  communication/adapters/herdr.md \
  communication/adapters/tmux.md \
  communication/adapters/orca.md
do
  [[ -f "${ROOT}/${file}" ]] || {
    echo "FAIL: missing ${file}"
    failed=1
  }
done

[[ "${failed}" -eq 0 ]] || exit 1

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

git -C "${tmp}" init -q
printf '# Existing\n' > "${tmp}/AGENTS.md"
printf '# Existing\n' > "${tmp}/CLAUDE.md"

(
  cd "${tmp}"
  "${ROOT}/install.sh" >/dev/null
)

for file in \
  .ai/workflow/BOOTSTRAP.md \
  .ai/workflow/CONFIG.md \
  .ai/workflow/PRINCIPLES.md \
  .ai/workflow/STATE.md \
  .ai/memory/ARCHI.md \
  .ai/workflow/skills/agent-workflow-orchestrator/SKILL.md \
  .ai/workflow/communication/protocol.md
do
  [[ -f "${tmp}/${file}" ]] || {
    echo "FAIL: install missing ${file}"
    exit 1
  }
done

grep -Fq '<!-- agent-workflow-bootstrap:start -->' "${tmp}/AGENTS.md"
grep -Fq '<!-- agent-workflow-bootstrap:start -->' "${tmp}/CLAUDE.md"

printf '\nPROJECT-SPECIFIC\n' >> "${tmp}/.ai/memory/ARCHI.md"
printf '\nPROJECT-STATE\n' >> "${tmp}/.ai/workflow/STATE.md"
printf '\nPROJECT-PRINCIPLE\n' >> "${tmp}/.ai/workflow/PRINCIPLES.md"

(
  cd "${tmp}"
  "${ROOT}/install.sh" >/dev/null
)

grep -Fq 'PROJECT-SPECIFIC' "${tmp}/.ai/memory/ARCHI.md"
grep -Fq 'PROJECT-STATE' "${tmp}/.ai/workflow/STATE.md"
grep -Fq 'PROJECT-PRINCIPLE' "${tmp}/.ai/workflow/PRINCIPLES.md"

(
  cd "${tmp}"
  "${ROOT}/uninstall.sh" >/dev/null
)

[[ ! -e "${tmp}/.ai/workflow/skills" ]]
[[ ! -e "${tmp}/.ai/workflow/communication" ]]
[[ ! -e "${tmp}/.ai/workflow/BOOTSTRAP.md" ]]
[[ -f "${tmp}/.ai/memory/ARCHI.md" ]]
[[ -f "${tmp}/.ai/workflow/CONFIG.md" ]]
[[ -f "${tmp}/.ai/workflow/PRINCIPLES.md" ]]
[[ -f "${tmp}/.ai/workflow/STATE.md" ]]
! grep -Fq '<!-- agent-workflow-bootstrap:start -->' "${tmp}/AGENTS.md"
! grep -Fq '<!-- agent-workflow-bootstrap:start -->' "${tmp}/CLAUDE.md"

echo "validation passed: 5 roles, 2 support skills, repository-local installation"
