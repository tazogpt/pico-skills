# Orca Adapter

Orca 앱이 관리하는 터미널로 역할을 연결한다. 명령은 실제 Orca CLI로 검증된 것만 기록한다.

Windows Orca와 WSL 조합에서는 `Path`/`PATH` 중복 및 UNC 현재 디렉터리 문제가 발생할 수 있다. 사용 전에 `orca-ide status --json`과 현재 worktree 선택이 정상 동작하는지 확인한다. 이 저장소는 별도 CLI 우회 설치 스크립트를 제공하지 않는다.

## IDENTIFY

```bash
orca terminal list --json
```

`title`이 herdr 탭 라벨에 대응하는 유일한 출처다.

역할 매핑 절차:

1. `result.terminals[]`에서 `worktreePath`가 현재 저장소인 터미널만 후보로 삼는다.
2. `title`을 배정 이름과 대조해 역할 → `handle`을 기록한다.

`title`이 배정 이름과 맞지 않으면 사용자에게 정리를 요청한다. 실행 중인 CLI나 모델로 추정하지 않는다.

`handle`은 터미널 재시작 시 바뀔 수 있다. 세션마다, 그리고 RESET 후에 다시 매핑한다.

## SEND

```bash
orca terminal send --terminal <handle> --text "<message>" --enter --json
```

JSON 응답의 `ok: true`로 제출을 확인한다. 긴 내용은 파일로 저장하고 경로만 보낸다.

## READ

```bash
orca terminal read --terminal <handle> --json
```

`result.terminal.tail`이 최신 화면 출력이다.

## WAIT_FOR

수신 에이전트가 직접 명령을 실행할 수 있으므로 화면 폴링보다 orchestration 메시지를 우선한다.

보고 측(각 역할)은 상태 반환 시 함께 실행한다.

```bash
orca orchestration send --to <orchestrator_handle> --subject "<STATUS>" --body "<artifact path>" --json
```

대기 측(오케스트레이터):

```bash
orca orchestration check --wait --timeout-ms <n> --json
```

orchestration을 쓸 수 없으면 `READ`를 폴링해 정확한 상태 문자열을 확인한다.

## RESET

새 터미널로 역할을 재배치하는 방식을 우선한다.

```bash
orca terminal create --worktree active --command "<cli>" --json
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json
```

이후 IDENTIFY를 다시 실행해 역할 → handle 매핑을 갱신한다.

## Worktree 주의

역할이 서로 다른 worktree의 터미널이면 커밋되지 않은 handoff 파일이 상대에게 보이지 않는다. 모든 역할을 같은 worktree의 터미널에 두거나, 파일을 커밋하거나, 메시지 본문으로 전달한다.

## Compatibility

`protocol.md`의 전체 상태 문자열이 손실 없이 왕복되어야 한다. 상태 목록을 여기에 다시 열거하지 않는다.
