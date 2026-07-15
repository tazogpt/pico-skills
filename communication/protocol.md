# Communication Protocol

역할 스킬과 실제 통신 도구 사이의 교체 가능한 계약이다.

역할은 다음 논리 연산만 사용한다.

```text
IDENTIFY(role)
SEND(role, message)
READ(role)
WAIT_FOR(role, expected_status)
RESET(role)
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
- orchestrator endpoint
```

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

새 통신 도구는 네 논리 연산과 상태 문자열을 그대로 지원한다.

도구별 제출 예외, Enter 처리, polling, timeout은 어댑터나 선택적 제어기에만 둔다.
