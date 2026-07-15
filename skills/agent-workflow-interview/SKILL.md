---
name: agent-workflow-interview
description: Use when the user's task request asks to be interviewed before design, to have intent confirmed before planning, or to be asked rather than assumed at.
metadata:
  version: "0.3.0"
---

# Interview

## Mission

Receive the user's intent exactly. Not reduce risk, not cover edge cases — find out what the user actually means and design that.

The architect runs this directly with the user. The orchestrator does not relay questions; choosing what to ask is a technical decision.

## Load condition

Load only when the user's task request asks for it.

Applies to that request only. It does not carry into the next task. When the next request does not ask for an interview, do not read this skill — design and review normally.

## Your output

Every reply during an interview is a status envelope plus a body.

The envelope is required. The orchestrator reads it to know whether you are waiting or done, so a reply without it strands the workflow:

```text
ARCHITECT_BLOCKED

REASON
- 무엇이 확정되지 않았고 답에 따라 무엇이 갈리는지

NEXT
- user decision
```

The body has these three parts, in this order:

1. **근거** — the facts you established in the repository, and what in the request they contradict or fail to determine
2. **질문 하나** — the single fork that changes the design most
3. **그 답이 무엇을 가르는지** — what you build if the answer is A, what you build if it is B

Those three are the whole body. The plan is not among them. You write the plan after the answers, in a later reply.

## Choosing the one question

Rank the open forks by how much of the design each one changes. Ask the top one.

A fork qualifies when different answers produce different plans. A question whose answers all lead to the same plan is not worth the user's time — resolve it yourself from the repository.

The strongest question is often the one that could make the whole task disappear. If the answer might turn six files into one line, that is the first question.

## Follow-up questions

Hold them. Make each one conditional on the answer you are waiting for, and say so:

```text
(B)일 때만 유효한 질문이 하나 더 있습니다. 지금은 묻지 않겠습니다.
```

Ask the next question after the answer arrives, in your next reply. Questions arrive one at a time because a batch forces the user to hold six open threads at once, and the later ones often evaporate once the first is answered.

## Options

Options are optional. An open question is fine when you have no strong candidates.

When you do offer options, offer at most 3. Usually one recommendation plus a free-form answer is enough. Make each option a concrete outcome the user can pick, not a category.

## Ending the interview

Stop asking when no remaining fork changes the design. Then write the plan and report `PLAN_READY` — the envelope changes from `ARCHITECT_BLOCKED` to `PLAN_READY`, and the body becomes the plan instead of the three parts.

## Urgency

Deadline pressure and idle roles are reasons to ask now, not reasons to skip asking. A wrong plan shipped today costs more than a question answered in 30 seconds. Let urgency narrow the scope of what you build; never let it narrow what you ask.

## Red flags

These sentences mean you have left the interview and started guessing:

| 나온 말 | 실제로 벌어진 일 |
|---|---|
| "나머지는 기본값으로 밀겠다" | 그 기본값이 곧 당신의 추측이다. 물어보기로 한 것을 혼자 정했다. |
| "답이 다 추천대로라면 계획은 이렇다" | 계획을 미리 썼다. 답은 이제 형식이 됐다. |
| "Q1~Q5" | 배치다. 하나만 남기고 나머지는 답에 종속시켜라. |
| "일단 가정하고 진행, ASSUMPTIONS에 적어둠" | 적어두는 것은 묻는 것이 아니다. 사용자는 그 문서를 읽지 않는다. |
| "급하니까 중요한 것만 묻자" | 급한 것은 범위를 줄일 이유다. 질문을 줄일 이유가 아니다. |
