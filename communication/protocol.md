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

TASK_ID
- id

ROLE
- 이 에이전트가 맡을 단일 역할

ASSIGNMENT
- orchestrator: <agent> (<endpoint>)
- architect: <agent> (<endpoint>)
- plan reviewer: <agent> (<endpoint>)
- implementer: <agent> (<endpoint>)
- implementation reviewer: <agent> (<endpoint>)

SKILL
- 읽어야 할 스킬 파일 경로

RETURN_TO
- orchestrator endpoint
```

수신 에이전트는 ROLE의 스킬만 읽고 `ROLE_READY`를 RETURN_TO로 반환한다. 5개 역할 배정 파싱은 하지 않는다.

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
