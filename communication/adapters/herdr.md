# herdr Adapter

## IDENTIFY

탭 라벨이 유일한 출처다.

```bash
herdr tab list
herdr pane list
```

1. `tab list`의 `label`을 배정 이름과 대조해 `tab_id`를 정한다.
2. `pane list`에서 그 `tab_id`를 가진 pane을 모은다.
3. 정확히 1개일 때만 그 `pane_id`를 endpoint로 기록한다. 2개 이상이면 `WORKFLOW_BLOCKED`를 보고하고 어느 pane인지 사용자에게 묻는다.

`herdr pane split`으로 한 탭이 여러 pane을 가질 수 있다. 라벨은 탭에 붙고 pane에는 붙지 않으므로, pane이 여러 개면 라벨만으로 대상이 정해지지 않는다. 이때 아무거나 고르면 다른 에이전트에게 `SEND`나 `RESET`이 간다. `tab list`의 `pane_count`로 미리 확인할 수 있다.

`pane list`의 `agent` 필드는 CLI 종류(`claude`, `codex`, `opencode`)까지만 알려주고 모델은 알려주지 않는다. 같은 CLI가 여러 pane에서 돌면 구분되지 않으므로 매핑에 쓰지 않는다. 상태줄의 모델명도 마찬가지다.

라벨이 배정 이름과 맞지 않으면 사용자에게 정리를 요청한다.

```bash
herdr tab rename <tab_id> <label>
```

세션마다, 그리고 RESET 후에 다시 확인한다.

## SEND

```bash
herdr pane run <target_pane_id> "<message>"
```

작업 지시는 역할 pane으로 보내고, 역할의 상태 보고는 받은 `MESSAGE`의 `RETURN_TO` pane으로 보낸다.

```bash
herdr pane run <role_pane_id> "<task MESSAGE>"
herdr pane run <return_to_pane_id> "<status MESSAGE>"
```

두 번째 명령은 상태를 오케스트레이터 pane의 새 입력으로 제출해 다음 turn을 시작한다. 역할이 자기 pane에 완료 상태를 출력하고 끝내면 보고가 전달되지 않는다.

환경상 제출이 확정되지 않을 때만 같은 target에 빈 입력을 추가로 보내고, 다른 pane에는 보내지 않는다.

```bash
herdr pane run <target_pane_id> "<message>"
sleep 1
herdr pane run <target_pane_id> ""
```

## READ

```bash
herdr pane read <pane_id>
```

## WAIT_FOR

정상 경로에서는 보고 역할이 `RETURN_TO` pane에 상태 `MESSAGE`를 push하므로, 수신 에이전트가 새 입력으로 상태를 받는다.

예상한 보고가 도착하지 않았을 때만 역할 pane을 `READ`해 정확한 상태 문자열을 복구한다. 자동화 시 timeout과 재시도 상한은 별도 제어기에 둔다.

## RESET

`herdr pane list`의 `agent` 필드로 CLI를 확인하고 해당 CLI의 초기화 명령을 보낸다.

```bash
herdr pane run <pane_id> "/clear"   # claude
herdr pane run <pane_id> "/new"     # codex
```

초기화 명령이 확인되지 않은 CLI는 사용자에게 수동 리셋을 요청한다. 리셋 후 IDENTIFY를 다시 실행한다.
