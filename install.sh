#!/usr/bin/env bash
# 워크플로우 스킬을 설치한다. 에이전트마다 스킬 탐색 경로가 다르므로 골라야 한다.
# 사용: ./install.sh claude|codex
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  claude)
    claude plugin marketplace add "$repo"
    claude plugin install pico-skills@pico-skills
    ;;
  codex)
    codex plugin marketplace add "$repo"
    codex plugin add pico-skills@pico-skills
    ;;
  *)
    echo "사용: $0 claude|codex" >&2
    echo "워크플로우에 참여하는 모든 탭에서 각자의 에이전트로 한 번씩 돌려야 한다." >&2
    exit 1
    ;;
esac
