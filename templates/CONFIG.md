# Workflow Configuration

## Policy

- plan_review: required
- implementation_review: required
- tdd: required-where-applicable
- commit: user-request-only
- push: user-request-only

## Paths

- architecture_memory: `.ai/memory/ARCHI.md`
- workflow_state: `.ai/workflow/STATE.md`
- skills_root: `.ai/workflow/skills`
- communication_root: `.ai/workflow/communication`

## Communication

- adapter: `auto`

`auto` 선택 순서:

1. 현재 환경에서 사용 가능한 herdr
2. 현재 tmux 세션
3. 저장소에 완성된 Orca 어댑터
4. 없으면 `WORKFLOW_BLOCKED`

통신 도구별 명령과 예외는 역할 스킬에 넣지 않는다.
