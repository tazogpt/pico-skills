#!/usr/bin/env bash
# Project-scoped Herdr session and tab launcher.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  pico-herdr create [PATH]
  pico-herdr open <TITLE> [PATH]
  pico-herdr info [PATH]

Commands:
  create        Create or attach to the current project's Herdr session.
  open TITLE    Create or focus a tab named TITLE.
  info          Print the resolved project and session names.

PATH defaults to the current directory. Inside a Git repository, its root is
used as the project directory.
EOF
}

for required in herdr git jq; do
  if ! command -v "$required" >/dev/null 2>&1; then
    echo "pico-herdr: required command not found: $required" >&2
    exit 1
  fi
done

command_name=${1:-}
if [[ -z "$command_name" || "$command_name" == -h || "$command_name" == --help ]]; then
  usage
  exit 0
fi
shift

title=""
case "$command_name" in
  create|info)
    ;;
  open)
    if (($# == 0)); then
      echo "pico-herdr: open requires a tab title" >&2
      exit 2
    fi
    title=$1
    shift
    ;;
  *)
    echo "pico-herdr: unknown command: $command_name" >&2
    usage >&2
    exit 2
    ;;
esac

if (($# > 1)); then
  echo "pico-herdr: expected at most one PATH" >&2
  exit 2
fi

path=${1:-$PWD}
if [[ ! -d "$path" ]]; then
  echo "pico-herdr: directory not found: $path" >&2
  exit 1
fi

physical_path=$(cd -- "$path" && pwd -P)
if git_root=$(git -C "$physical_path" rev-parse --show-toplevel 2>/dev/null); then
  project_path=$(cd -- "$git_root" && pwd -P)
else
  project_path=$physical_path
fi

project_session=$(basename -- "$project_path")
[[ "$project_path" == / ]] && project_session=root
project_session=$(sed -E 's/[^[:alnum:]_.-]+/-/g; s/^-+//; s/-+$//' <<<"$project_session")
if [[ -z "$project_session" || "$project_session" == default ]]; then
  echo "pico-herdr: could not derive a safe session name from: $project_path" >&2
  exit 1
fi

if [[ "$command_name" == info ]]; then
  printf 'project=%s\nsession=%s\n' "$project_path" "$project_session"
  exit 0
fi

if [[ "$command_name" == create ]]; then
  if [[ ${HERDR_ENV:-} == 1 && ${HERDR_SESSION:-} == "$project_session" ]]; then
    echo "pico-herdr: already in session $project_session" >&2
    exit 0
  fi
  echo "pico-herdr: opening session $project_session" >&2
  cd -- "$project_path"
  exec herdr --session "$project_session"
fi

# `open` targets the enclosing Herdr session when called from a Herdr pane.
# Outside Herdr it targets the deterministic project session.
session=$project_session
if [[ ${HERDR_ENV:-} == 1 && -n ${HERDR_SESSION:-} ]]; then
  session=$HERDR_SESSION
fi

session_running() {
  herdr session list --json |
    jq -e --arg session "$session" '.sessions[]? | select(.name == $session and .running == true)' \
      >/dev/null
}

if ! session_running; then
  state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/pico-herdr
  mkdir -p "$state_dir"
  log_path=$state_dir/$session.log
  (
    cd -- "$project_path"
    nohup herdr --session "$session" server >"$log_path" 2>&1 </dev/null &
  )

  for _ in $(seq 1 50); do
    session_running && break
    sleep 0.1
  done

  if ! session_running; then
    echo "pico-herdr: failed to start session $session; see $log_path" >&2
    exit 1
  fi
fi

# `ph open` opens a tab in the current workspace. When called from an ordinary
# shell there is no current workspace environment, so use the first workspace
# in the session (or create a project workspace to contain the new tab).
workspace_id=""
if [[ ${HERDR_ENV:-} == 1 && ${HERDR_SESSION:-} == "$session" && -n ${HERDR_WORKSPACE_ID:-} ]]; then
  workspace_id=$HERDR_WORKSPACE_ID
else
  workspace_list=$(herdr --session "$session" workspace list)
  workspace_id=$(jq -r '.result.workspaces[0].workspace_id // empty' <<<"$workspace_list")

  if [[ -z "$workspace_id" ]]; then
    created_workspace=$(
      herdr --session "$session" workspace create \
        --cwd "$project_path" \
        --label "$project_session" \
        --focus
    )
    workspace_id=$(jq -r '.result.workspace.workspace_id // empty' <<<"$created_workspace")
  fi
fi

if [[ -z "$workspace_id" ]]; then
  echo "pico-herdr: Herdr did not return a workspace id" >&2
  exit 1
fi

tab_list=$(herdr --session "$session" tab list --workspace "$workspace_id")
tab_id=$(
  jq -r --arg title "$title" \
    '.result.tabs[]? | select(.label == $title) | .tab_id' \
    <<<"$tab_list" |
    head -1
)

if [[ -n "$tab_id" ]]; then
  herdr --session "$session" tab focus "$tab_id" >/dev/null
  echo "pico-herdr: focused tab $title ($tab_id)" >&2
else
  created_tab=$(
    herdr --session "$session" tab create \
      --workspace "$workspace_id" \
      --cwd "$project_path" \
      --label "$title" \
      --focus
  )
  tab_id=$(jq -r '.result.tab.tab_id // empty' <<<"$created_tab")
  if [[ -z "$tab_id" ]]; then
    echo "pico-herdr: Herdr did not return a tab id" >&2
    exit 1
  fi
  echo "pico-herdr: created tab $title ($tab_id)" >&2
fi

# An existing Herdr client receives the focus change directly. From an ordinary
# shell, attach to the project session after creating/focusing the tab.
if [[ ${HERDR_ENV:-} == 1 && ${HERDR_SESSION:-} == "$session" ]]; then
  exit 0
fi

cd -- "$project_path"
exec herdr --session "$session"
