# tmux Adapter

## IDENTIFY

window 이름이 herdr 탭 라벨에 대응하는 유일한 출처다.

```bash
tmux list-windows -a -F '#{session_name}:#{window_index} #{window_name}'
tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index} #{pane_id}'
```

1. `window_name`을 배정 이름과 대조해 window를 정한다.
2. 그 window의 pane을 모은다.
3. 정확히 1개일 때만 그 pane target을 endpoint로 기록한다. 2개 이상이면 `WORKFLOW_BLOCKED`를 보고하고 어느 pane인지 사용자에게 묻는다.

이름은 window에 붙고 pane에는 붙지 않는다. window가 분할돼 있으면 이름만으로 대상이 정해지지 않으며, 아무거나 고르면 다른 에이전트에게 `SEND`나 `RESET`이 간다.

`pane_current_command`는 CLI 종류까지만 알려주므로 매핑에 쓰지 않는다.

이름이 배정과 맞지 않으면 사용자에게 정리를 요청한다.

```bash
tmux rename-window -t <target> <name>
```

현재 세션마다, 그리고 RESET 후에 다시 매핑한다.

## SEND

```bash
tmux send-keys -t <target_pane> -l -- "<message>"
tmux send-keys -t <target_pane> Enter
```

작업 지시는 역할 pane으로 보내고, 역할의 상태 보고는 받은 `MESSAGE`의 `RETURN_TO` pane으로 보낸다. 상태를 자기 pane에 출력하는 것만으로는 반환되지 않는다.

## READ

```bash
tmux capture-pane -p -t <target> -S -200
```

## WAIT_FOR

정상 경로에서는 보고 역할이 `RETURN_TO` pane에 상태 `MESSAGE`를 push하므로, 수신 에이전트가 새 입력으로 상태를 받는다.

예상한 보고가 도착하지 않았을 때만 역할 pane을 캡처해 정확한 상태 문자열을 복구한다. polling, timeout, 중복 응답 방지는 선택적 제어기에 둔다.

## RESET

초기화 명령은 tmux가 아니라 대상 CLI의 기능이다. pane에서 실행 중인 CLI를 먼저 확인한다.

```bash
tmux send-keys -t <target> -l -- "/clear"   # Claude Code
tmux send-keys -t <target> Enter
```

Codex CLI는 `/new`를 사용한다. 초기화 명령이 확인되지 않은 CLI는 pane에서 세션을 종료하고 새로 시작한다. 리셋 후 IDENTIFY를 다시 실행한다.
