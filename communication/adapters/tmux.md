# tmux Adapter

## IDENTIFY

```bash
tmux list-panes -a \
  -F '#{session_name}:#{window_index}.#{pane_index} #{pane_id} #{pane_current_command} #{pane_title}'
```

현재 세션마다 다시 매핑한다.

## SEND

```bash
tmux send-keys -t <target> -l -- "<message>"
tmux send-keys -t <target> Enter
```

## READ

```bash
tmux capture-pane -p -t <target> -S -200
```

## WAIT_FOR

캡처 결과에서 정확한 상태 문자열을 확인한다.

polling, timeout, 중복 응답 방지는 선택적 제어기에 둔다.

## RESET

초기화 명령은 tmux가 아니라 대상 CLI의 기능이다. pane에서 실행 중인 CLI를 먼저 확인한다.

```bash
tmux send-keys -t <target> -l -- "/clear"   # Claude Code
tmux send-keys -t <target> Enter
```

Codex CLI는 `/new`를 사용한다. 초기화 명령이 확인되지 않은 CLI는 pane에서 세션을 종료하고 새로 시작한다. 리셋 후 IDENTIFY를 다시 실행한다.
