# herdr Adapter

## IDENTIFY

```bash
herdr pane list
```

현재 세션마다 다시 확인하고 `agent`, `pane_id`를 역할에 매핑한다.

## SEND

```bash
herdr pane run <pane_id> "<message>"
```

환경상 완료 상태 제출이 확정되지 않을 때만 어댑터 내부에서 추가 제출한다.

```bash
herdr pane run <pane_id> "IMPLEMENTATION_COMPLETE ..."
sleep 1
herdr pane run <pane_id> ""
```

## READ

```bash
herdr pane read <pane_id>
```

## WAIT_FOR

`READ` 결과에서 정확한 상태 문자열을 확인한다.

자동화 시 timeout과 재시도 상한은 별도 제어기에 둔다.

## RESET

`herdr pane list`의 `agent` 필드로 CLI를 확인하고 해당 CLI의 초기화 명령을 보낸다.

```bash
herdr pane run <pane_id> "/clear"   # claude
herdr pane run <pane_id> "/new"     # codex
```

초기화 명령이 확인되지 않은 CLI는 사용자에게 수동 리셋을 요청한다. 리셋 후 IDENTIFY를 다시 실행한다.
