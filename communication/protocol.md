# Communication Protocol

역할 스킬과 실제 통신 도구 사이의 교체 가능한 계약이다.

역할은 다음 논리 연산만 사용한다.

```text
IDENTIFY(assigned_name)
SEND(endpoint, message)
READ(endpoint)
WAIT_FOR(endpoint, expected_status)
RESET(endpoint)
```

## IDENTIFY

배정 이름을 endpoint로 해석한다. 어댑터의 **탭 라벨이 유일한 출처다.**

pane에서 실행 중인 CLI 종류와 상태줄의 모델명은 라우팅에 쓰지 않는다. 참고 정보일 뿐이다. 같은 CLI가 같은 모델로 여러 pane에서 돌 수 있으므로 구분 기준이 되지 못한다. 모델이나 CLI를 바꿔도 라벨이 유지되면 워크플로는 그대로 동작한다.

1. 어댑터로 탭 라벨과 endpoint 목록을 읽는다.
2. 배정 이름을 라벨과 대조한다. 한글과 영문, 부분 이름의 대응은 에이전트가 판단한다. `프로`와 `opencode-pro`, `코덱스솔`과 `sol`은 같은 대상이다.
3. 하나로 확정되지 않으면 `WORKFLOW_BLOCKED`를 보고하고 사용자에게 묻는다. 추측이나 소거법으로 채우지 않는다.

각 역할의 식별 근거는 `label <라벨>`로 기록한다.

세션마다, 그리고 RESET 후에 다시 실행한다.

## Message

```text
MESSAGE

TASK_ID
- id

FROM
- role

TO
- role

STATUS
- exact status

ARTIFACTS
- file paths or diff

SUMMARY
- concise content

OPEN
- blockers

RETURN_TO
- 이 메시지에 대한 응답을 받을 endpoint
```

## Status delivery

역할의 작업이 끝나거나 사용자 결정을 기다리게 되면, 상태 보고를 현재 작업 `MESSAGE`의 `RETURN_TO` endpoint로 `SEND`한다. 보고는 상대 pane에 새 입력으로 제출되어 상대 에이전트를 깨워야 한다.

```text
SEND(RETURN_TO, MESSAGE with exact STATUS)
```

- `PLAN_READY`, 리뷰 verdict, TDD 결과, `IMPLEMENTATION_COMPLETE`, `ARCHITECT_ACCEPTED`, `*_BLOCKED`를 모두 같은 방식으로 보낸다.
- 자기 pane에 상태를 출력하는 것만으로는 반환이 아니다. 필요하면 로컬 기록을 남길 수 있지만 상대 pane 전송을 대신하지 못한다.
- 보고 역할은 `.ai/workflow/STATE.md`의 `communication_adapter`를 읽고 해당 어댑터의 `SEND` 절차로 `RETURN_TO` endpoint에 제출한다.
- 보고 `MESSAGE`는 원래 `TASK_ID`, 보고 역할 `FROM`, 수신 역할 `TO`, 정확한 `STATUS`, 산출물과 요약을 유지한다. 역할 스킬의 상태별 출력 필드도 생략하지 않는다.
- 보고 `MESSAGE`의 `RETURN_TO`에는 이후 응답을 받을 보고 역할의 endpoint를 넣는다.
- 수신 측은 새 입력의 `TASK_ID`, `FROM`, `TO`, `STATUS`를 현재 상태와 대조한 뒤 전이한다.
- `READ`는 전송 누락을 복구할 때만 사용한다. 정상 완료 경로를 화면 polling에 의존하지 않는다.

`ROLE_READY`만 예외다. 활성화 봉투에는 `RETURN_TO`가 없고 즉시 끝나는 확인이므로 오케스트레이터가 대상 pane을 `READ`해 회수한다.

## Role activation

오케스트레이터가 역할을 처음 활성화할 때 보낸다. `워크플로워`로 시작하므로 수신 에이전트의 부트스트랩 트리거와 호환된다.

```text
워크플로워 ROLE_ACTIVATE

ROLE
- 이 에이전트가 맡을 단일 역할
```

역할명 외에는 보내지 않는다.

- 스킬 경로는 역할명에서 결정된다. 공백을 `-`로 바꿔 `.ai/workflow/skills/agent-workflow-<role>/SKILL.md`가 된다. `plan reviewer`는 `agent-workflow-plan-reviewer`다.
- 반환 주소는 필요 없다. 오케스트레이터가 `READ`로 회수한다.
- `TASK_ID`와 작업 내용은 이후 `MESSAGE`로 전달한다. 활성화는 역할 진입까지만 담당한다.
- 5개 역할 배정표는 수신 에이전트가 쓰지 않는다. 라우팅은 오케스트레이터만 한다.

수신 에이전트는 ROLE의 스킬만 읽고 자신의 pane에 `ROLE_READY`를 출력한다.

```text
ROLE_READY

ROLE
- <assigned role>
```

## RESET

같은 에이전트가 계획 리뷰어와 구현 리뷰어를 모두 맡을 때 구현 리뷰 활성화 전에 실행한다.

1. 어댑터의 RESET 절차를 실행한다. 컨텍스트 초기화 명령은 통신 도구가 아니라 대상 CLI의 기능이므로 어댑터가 CLI별로 확인한다.
2. 성공을 확인할 수 없으면 사용자에게 수동 리셋을 요청하고 대기한다.
3. 리셋 후 `IDENTIFY`를 다시 실행해 endpoint를 갱신한다.

## Status

```text
ROLE_READY
WORKFLOW_READY
PLAN_READY
PLAN_REVIEW_PASS
PLAN_REVIEW_CHANGES
TDD_APPLICABLE
TDD_NOT_APPLICABLE
TDD_COMPLETE
TDD_BLOCKED
IMPLEMENTATION_COMPLETE
IMPLEMENTATION_REVIEW_PASS
IMPLEMENTATION_REVIEW_CHANGES
IMPLEMENTATION_REVIEW_REPLAN
ARCHITECT_ACCEPTED
ARCHITECT_BLOCKED
WORKFLOW_COMPLETE
WORKFLOW_BLOCKED
```

## Long content

긴 계획, 리뷰, 구현 지시는 파일로 저장하고 경로만 보낸다.

권장 저장 위치:

```text
docs/tasks/<task-id>/
```

계획 문서의 `docs/plans/`와 같은 위계다. git에 추적되며, 없으면 쓰는 쪽이 생성한다. 태스크별 하위 디렉터리로 이전 태스크 산출물과 섞이지 않게 한다.

## Adapter rule

새 통신 도구는 다섯 논리 연산과 상태 문자열을 그대로 지원한다.

도구별 제출 예외, Enter 처리, polling, timeout은 어댑터나 선택적 제어기에만 둔다.
