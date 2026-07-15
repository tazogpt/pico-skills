---
name: agent-workflow-tdd
description: Assess TDD applicability for an approved change and, when applicable, guide the implementer through evidence-based Red-Green-Refactor cycles for only the selected behavior without changing scope or architecture.
metadata:
  version: "0.3.0"
---

# TDD Support

This is a support skill, not a workflow role.

Modes:

```text
ASSESS
EXECUTE
```

ASSESS is run by the architect after plan approval. EXECUTE is applied by the implementer to the selected scopes.

## Boundaries

- No scope or architecture changes
- No invented requirements
- No forced TDD for unsuitable work
- No meaningless process tests
- No coverage-percentage proxy
- No replacement of necessary integration or manual verification

## ASSESS

### Good candidates

- domain and business rules
- deterministic transformations
- parsers, validators, mappers
- reproducible bug fixes
- services with stable seams
- state transitions
- stable API contracts
- authorization decisions
- boundary and error behavior

### Usually unsuitable

- documentation or formatting
- generated code
- pure wiring
- one-off build configuration
- exploratory spikes
- visual-only UI without an automated seam
- external systems without deterministic control
- tests requiring disproportionate new infrastructure

Mixed tasks may select only part of the scope.

### Questions

1. Can behavior be stated before implementation?
2. Can a stable seam observe it?
3. Can the test fail for the intended reason?
4. Is it deterministic?
5. Is setup proportionate?
6. Will the test retain regression value?

### Applicable

```text
TDD_APPLICABLE

SCOPES
- behavior and seam

FIRST_TESTS
- observable behavior
- expected failure

COMMANDS
- targeted command

NON_TDD_SCOPE
- alternative verification
```

### Not applicable

```text
TDD_NOT_APPLICABLE

REASON
- technical reason

VERIFICATION
- alternative checks
```

### Blocked

```text
TDD_BLOCKED

REASON
- missing decision or capability

NEEDS
- architect decision / environment
```

## EXECUTE

### RED

1. Write one test for one missing behavior.
2. Run the narrowest command.
3. Confirm failure.
4. Confirm the failure is the missing behavior.
5. Record evidence.

A passing new test is not RED evidence.

### GREEN

1. Make the minimum production change.
2. Run the targeted test.
3. Run directly related tests.
4. Record evidence.

No speculative abstraction.

### REFACTOR

1. Improve structure without behavior change.
2. Stay in scope.
3. Re-run targeted and regression tests.
4. Record evidence.

### Bug fix

1. Add a regression test reproducing the bug.
2. Confirm RED.
3. Apply the smallest valid fix.
4. Confirm the regression and neighboring tests pass.

### Stop

Stop and report when:

- behavior is ambiguous
- a stable test requires an unapproved contract change
- the seam requires disproportionate architecture work
- RED exposes a plan defect
- the environment prevents trustworthy evidence

Do not silently switch to test-after.

## Report

```text
TDD_COMPLETE

SCOPES
- completed behavior

RED
- test, command, failure

GREEN
- change, command, pass

REFACTOR
- cleanup, regression evidence

OPEN
- remaining verification
```
