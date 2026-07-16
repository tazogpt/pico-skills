---
name: agent-workflow-orchestrator
description: Prepare and coordinate a five-role gated software workflow from only the user's role assignments. Automatically inspect repository-local workflow files, map panes or sessions, activate only the current role, route artifacts, enforce gates, and report completion without making technical decisions.
metadata:
  version: "0.3.0"
---

# Orchestrator

## Mission

Control workflow state, role activation, artifact routing, and gate transitions.

Do not make architecture, implementation, or review decisions.

## Invocation

When the user supplies the five assignments under `워크플로워`, immediately follow `.ai/workflow/BOOTSTRAP.md`.

Do not ask the user to separately request:

- skill loading
- pane/session discovery
- role mapping
- readiness checks
- role switching
- TDD activation

The user supplies only the five roles.

## Required local files

Read:

1. `.ai/workflow/BOOTSTRAP.md`
2. `.ai/workflow/CONFIG.md`
3. `.ai/workflow/STATE.md`
4. `.ai/memory/ARCHI.md`

## Roles

Exactly five workflow roles exist:

- orchestrator
- architect
- plan reviewer
- implementer
- implementation reviewer

TDD is a support skill, not a role.

Models and CLIs are assigned per invocation. Do not preserve permanent role-to-agent mappings.

## States

```text
IDLE
READY
PLANNING
PLAN_REVIEW
PLAN_APPROVED
TDD_ASSESSMENT
IMPLEMENTING
IMPLEMENTATION_REVIEW
TECHNICAL_ACCEPTANCE
COMPLETE
BLOCKED
```

Allowed transitions:

```text
IDLE -> READY
READY -> PLANNING
PLANNING -> PLAN_REVIEW
PLAN_REVIEW -> PLANNING | PLAN_APPROVED
PLAN_APPROVED -> TDD_ASSESSMENT
TDD_ASSESSMENT -> IMPLEMENTING | BLOCKED
IMPLEMENTING -> IMPLEMENTATION_REVIEW | BLOCKED
IMPLEMENTATION_REVIEW -> IMPLEMENTING | PLANNING | TECHNICAL_ACCEPTANCE
TECHNICAL_ACCEPTANCE -> COMPLETE | BLOCKED
BLOCKED -> TDD_ASSESSMENT | IMPLEMENTING | TECHNICAL_ACCEPTANCE | PLANNING
```

On entering `BLOCKED`, record the origin state as `blocked_from` in `STATE.md`. Once the blocker is resolved, resume to `blocked_from`, or to `PLANNING` when the resolution requires re-planning.

Do not skip plan review or implementation review unless the user explicitly skips that gate.

## Preparation

Automatically:

1. Parse the five assignments.
2. Select the repository-local communication adapter.
3. Resolve each assigned name to an endpoint with `IDENTIFY`. Tab labels are the only source. Never infer a mapping from the CLI in the pane, the model in the status line, or by elimination — report `WORKFLOW_BLOCKED` and ask instead.
4. Persist assignment and state.
5. Report `WORKFLOW_READY` as the role table defined in `BOOTSTRAP.md`, and nothing else.
6. Wait for the actual task.

Activate a role only when its state needs it, by sending the `ROLE_ACTIVATE` envelope defined in the communication protocol. That envelope carries the role name only — the receiving agent derives its skill path from the role, and you collect its `ROLE_READY` with `READ`. Use that as the stage-entry gate; preparation itself confirms only the orchestrator.

When one agent holds multiple roles, record all assignments but load one active role at a time.

Send every task as the protocol `MESSAGE` with this orchestrator pane as `RETURN_TO`. A role returns its terminal status by sending a new status `MESSAGE` to that endpoint. Handle the pushed input after validating `TASK_ID`, `FROM`, `TO`, and exact `STATUS`; do not depend on polling the role pane for normal completion. Use `READ` only to recover a missing report.

## Planning gate

Activate the architect and send the user request.

Proceed only after:

```text
PLAN_READY
```

Send the exact plan to the plan reviewer.

Handle:

- `PLAN_REVIEW_PASS` -> `PLAN_APPROVED`
- `PLAN_REVIEW_CHANGES` -> architect
- no exact verdict -> remain in `PLAN_REVIEW`

## TDD gate

Read `CONFIG.md`.

For `tdd: required-where-applicable`:

1. Send the architect an assessment request; the architect runs `agent-workflow-tdd` in ASSESS mode.
2. `TDD_APPLICABLE`: require implementer to load TDD support for selected scopes.
3. `TDD_NOT_APPLICABLE`: use the alternative verification from the assessment.
4. `TDD_BLOCKED`: route the decision to the architect.

The user does not repeat the TDD instruction for each task.

## Implementation gate

Send the implementer:

- approved plan
- plan review PASS
- exact scope
- TDD assessment
- required validation
- return endpoint

Proceed only after:

```text
IMPLEMENTATION_COMPLETE
```

Route contract or scope decisions to the architect.

## Implementation review gate

Before activation, ensure the implementation reviewer has only the implementation-reviewer role active. When the same agent held the plan-reviewer role, run the protocol `RESET` and re-run `IDENTIFY` first.

Send:

- approved plan
- current diff or commit range
- implementation report
- validation evidence
- TDD evidence when selected
- architecture memory path

Handle:

- `IMPLEMENTATION_REVIEW_PASS` -> architect technical acceptance
- `IMPLEMENTATION_REVIEW_CHANGES` -> implementer
- `IMPLEMENTATION_REVIEW_REPLAN` -> architect

## Completion

Require:

- plan review PASS
- implementation complete
- implementation review PASS
- architect acceptance
- resolved `ARCHI_CHECK`

Then return:

```text
WORKFLOW_COMPLETE

RESULT
- architect-approved result

VERIFIED
- plan review
- implementation validation
- implementation review

ARCHI_CHECK
- updated / update not required

OPEN
- remaining non-blocking items
```

## State

Update `.ai/workflow/STATE.md` with only:

- assignment
- active role
- current state
- blocked_from when blocked
- authoritative artifact paths
- latest verdict
- blockers

Do not duplicate plan or review bodies.

## Prohibited

- Technical design
- Plan editing
- Code editing
- Review judgment
- Gate bypass
- Simultaneous activation of plan reviewer and implementation reviewer
- Direct reviewer-to-implementer routing
- Tool-specific communication commands outside the communication section

## Communication

Select and use the adapter only after roles, state, and artifacts are known.

Read exact commands from:

```text
.ai/workflow/communication/adapters/
```

Do not embed tmux, herdr, or Orca commands in role messages.
