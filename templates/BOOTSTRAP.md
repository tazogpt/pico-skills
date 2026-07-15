# Workflow Bootstrap

사용자가 `워크플로워`로 시작하는 메시지에 다음 5개 역할을 지정하면 실행한다.

```text
오케스트레이터:
아키텍트:
계획 리뷰어:
임플리먼터:
구현 리뷰어:
```

사용자에게 스킬 로드, pane 확인, 역할 전환, 준비 명령을 추가로 요구하지 않는다.

메시지가 `워크플로워 ROLE_ACTIVATE`로 시작하면 원격 활성화다. 아래 5개 역할 파싱을 건너뛰고, 메시지의 ROLE에 해당하는 스킬만 읽은 뒤 `ROLE_READY`를 출력한다. 활성화 메시지는 역할명만 담는다.

## 1. 입력 검증

정확히 다음 5개 역할의 담당자를 읽는다.

- orchestrator
- architect
- plan reviewer
- implementer
- implementation reviewer

동일한 에이전트가 여러 역할을 맡을 수 있다.

누락된 역할이 있으면 누락 역할만 보고한다. 역할이 모두 있으면 추가 질문 없이 준비를 시작한다.

TDD는 역할 배정으로 받지 않는다. `.ai/workflow/CONFIG.md`의 정책을 따른다.

## 2. 저장소 확인

다음을 읽는다.

1. `.ai/workflow/CONFIG.md`
2. `.ai/workflow/STATE.md`
3. `.ai/memory/ARCHI.md`

현재 작업 디렉터리가 Git 저장소가 아니면 `WORKFLOW_BLOCKED`를 보고한다.

## 3. 현재 에이전트 역할 선택

현재 에이전트가 배정된 역할만 취급한다.

- 오케스트레이터 담당자: orchestrator 스킬을 로드하고 전체 준비를 통제한다.
- 아키텍트 담당자: architect 스킬을 로드한다.
- 계획 리뷰어 담당자: plan-reviewer 스킬을 로드한다.
- 임플리먼터 담당자: implementer 스킬을 로드한다.
- 구현 리뷰어 담당자: 구현 리뷰 단계가 시작될 때 implementation-reviewer 스킬을 로드한다.

같은 에이전트가 계획 리뷰어와 구현 리뷰어를 모두 맡으면:

1. 준비 단계에는 계획 리뷰어만 활성화한다.
2. 계획 리뷰 완료 후 해당 역할을 종료한다.
3. 구현 리뷰 전에 통신 프로토콜의 `RESET`을 실행하고 `IDENTIFY`로 endpoint를 재확인한다.
4. 구현 리뷰어 스킬만 새로 로드한다.

다른 역할의 상세 스킬은 읽지 않는다.

## 4. pane/session 준비

오케스트레이터가 통신 어댑터를 선택한 뒤 통신 프로토콜의 `IDENTIFY`로 전체 endpoint를 확정한다. 탭 라벨이 유일한 출처다.

역할 담당자는 다음을 출력한다.

```text
ROLE_READY

ROLE
- <assigned role>
```

담당 에이전트와 endpoint는 오케스트레이터가 이미 알고 있으므로 반환하지 않는다.

준비 단계에서 `ROLE_READY`를 반환하는 것은 오케스트레이터 자신뿐이다. 다른 역할은 최초 활성화(`ROLE_ACTIVATE` 수신) 시 반환하며, 오케스트레이터는 이를 해당 단계 진입 게이트로 사용한다.

준비 단계에서는 설계, 리뷰, 구현을 시작하지 않는다.

## 5. 준비 완료

오케스트레이터는 5개 역할의 배정과 endpoint 매핑을 기록하고 자신의 준비만 확인한다. 나머지 역할의 `ROLE_READY`는 각 역할 최초 활성화 시 수집한다.

같은 담당자가 여러 역할이면 endpoint 중복은 허용하지만 역할 전환 규칙을 기록한다.

완료 출력:

```text
WORKFLOW_READY

| 역할 | 담당 | endpoint | 근거 |
| --- | --- | --- | --- |
| orchestrator | <agent> | <endpoint> | label <라벨> |
| architect | <agent> | <endpoint> | label <라벨> |
| plan reviewer | <agent> | <endpoint> | label <라벨> |
| implementer | <agent> | <endpoint> | label <라벨> |
| implementation reviewer | <agent> | <endpoint> | label <라벨> |
```

표 외에는 출력하지 않는다. 정책은 `CONFIG.md`에 있고, 어느 역할이 언제 활성화되는지는 고정된 흐름에서 결정되므로 다시 적지 않는다.

`WORKFLOW_READY` 이후 사용자 작업 지시를 기다린다.

## 6. 통신 선택

통신은 가장 마지막에 결합한다.

`CONFIG.md`가 `adapter: auto`이면 다음 순서로 확인한다.

1. `herdr pane list`가 정상 동작하면 herdr
2. 현재 tmux 세션이면 tmux
3. 완성된 Orca 어댑터가 있으면 Orca
4. 모두 불가능하면 `WORKFLOW_BLOCKED`

도구별 명령은 `.ai/workflow/communication/adapters/`에서만 읽는다.
