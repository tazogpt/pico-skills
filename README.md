# Agent Workflow Skills

현재 Git 저장소에만 설치하는 개인용 멀티 에이전트 워크플로다.

사용자는 워크플로 준비 시 **5개 역할만 지정한다.**

```text
워크플로워
오케스트레이터: Claude
아키텍트: Claude
계획 리뷰어: Codex
임플리먼터: OpenCode
구현 리뷰어: Codex
```

스킬 로드, 현재 pane 확인, 역할 매핑, 단계별 역할 전환, 준비 확인은 자동으로 수행한다.

TDD는 역할이 아니다. 저장소 기본 정책에 따라 구현 전에 별도 TDD 스킬이 적용 가능성을 판정하고, 가능한 범위는 TDD로 구현한다.

## 구성

### 역할 스킬 5개

- `agent-workflow-orchestrator`
- `agent-workflow-architect`
- `agent-workflow-plan-reviewer`
- `agent-workflow-implementer`
- `agent-workflow-implementation-reviewer`

### 지원 스킬

- `agent-workflow-tdd`

### 저장소 파일

```text
.ai/
├─ memory/
│  └─ ARCHI.md
└─ workflow/
   ├─ BOOTSTRAP.md
   ├─ CONFIG.md
   ├─ STATE.md
   ├─ skills/
   └─ communication/
```

세션 통신으로 넘기기에 너무 긴 내용(계획, 리뷰, 구현 지시)은 문서로 먼저 저장하고 경로만 전달한다. 계획은 `docs/plans/`, 그 외 태스크 산출물은 `docs/tasks/<task-id>/`에 저장하며 필요할 때 에이전트가 생성한다.

## 자동 준비

`워크플로워` 명령을 받은 에이전트는 `.ai/workflow/BOOTSTRAP.md`를 따른다.

자동 수행 항목:

1. 현재 Git 저장소 루트 확인
2. `CONFIG.md`, `STATE.md`, `ARCHI.md` 확인
3. 사용자 메시지에서 5개 역할 배정 파싱
4. 현재 pane/session 확인
5. 에이전트와 역할 매핑
6. 현재 단계에 필요한 역할 스킬만 로드
7. 같은 에이전트가 복수 역할이면 단계별로 전환
8. 각 역할의 `ROLE_READY`는 최초 활성화 시 확인
9. 오케스트레이터가 `WORKFLOW_READY` 보고
10. 다음 사용자 작업 지시 전까지 설계·리뷰·구현 금지

## 기본 흐름

```text
사용자의 5개 역할 배정
  ↓
자동 준비
  ↓
아키텍트 계획
  ↓
계획 리뷰어
  ↓
TDD 적용 가능성 판정
  ↓
임플리먼터
  ↓
구현 리뷰어
  ↓
아키텍트 최종 승인
```

## 현재 저장소에 설치

워크플로 저장소를 private Git에 올린 뒤, 대상 프로젝트 내부에 submodule로 추가하는 방식을 권장한다.

대상 프로젝트 루트에서 실행:

```bash
git submodule add \
  git@github.com:YOUR_ACCOUNT/agent-workflow-skills.git \
  .ai/vendor/agent-workflow-skills

./.ai/vendor/agent-workflow-skills/install.sh
```

`install.sh`는 **현재 작업 디렉터리가 속한 Git 저장소**에만 설치한다. 전역 홈 디렉터리는 사용하지 않는다.

설치되는 항목:

- `.ai/workflow/skills/`
- `.ai/workflow/communication/`
- `.ai/workflow/BOOTSTRAP.md`
- `.ai/workflow/CONFIG.md` — 없을 때만 생성
- `.ai/workflow/STATE.md` — 없을 때만 생성
- `.ai/memory/ARCHI.md` — 없을 때만 생성
- `AGENTS.md`, `CLAUDE.md`의 최소 부트스트랩 블록

기존 `CONFIG.md`, `STATE.md`, `ARCHI.md`는 덮어쓰지 않는다.

### 일반 clone

submodule을 사용하지 않는 경우:

```bash
git clone \
  git@github.com:YOUR_ACCOUNT/agent-workflow-skills.git \
  .ai/vendor/agent-workflow-skills

./.ai/vendor/agent-workflow-skills/install.sh
```

## 업데이트

submodule 방식:

```bash
git submodule update --remote --merge .ai/vendor/agent-workflow-skills
./.ai/vendor/agent-workflow-skills/install.sh
```

역할 스킬, 부트스트랩, 통신 어댑터는 갱신된다. 저장소별 설정·상태·아키텍처 메모리는 보존된다.

## 제거

```bash
./.ai/vendor/agent-workflow-skills/uninstall.sh
```

워크플로가 관리하는 역할 스킬, 통신 파일, 부트스트랩 블록만 제거한다.

다음은 프로젝트 데이터이므로 자동 삭제하지 않는다.

- `.ai/workflow/CONFIG.md`
- `.ai/workflow/STATE.md`
- `.ai/memory/ARCHI.md`
- `docs/plans/`, `docs/tasks/`

## 검증

```bash
./scripts/validate.sh
```

검증 항목:

- 5개 역할 스킬 존재
- TDD 지원 스킬 존재
- 스킬 frontmatter 검증
- 필수 템플릿 존재
- 통신 어댑터 존재
- 실제 임시 Git 저장소에 로컬 설치
- 재설치 시 프로젝트 데이터 보존
- 제거 시 프로젝트 데이터 보존

## Orca WSL CLI 수리

Orca 앱이 Windows이고 저장소가 WSL이면 `orca` CLI가 중복 환경변수(`Path`/`PATH`)로 시작 시 죽는다. WSL interop이 Linux `PATH`를 Windows 프로세스에 강제 주입하기 때문이며, WSL 쪽에서는 막을 수 없다.

```bash
./scripts/install-orca-wsl-cli.sh
```

PowerShell 셤이 Windows 프로세스 안에서 중복 키를 제거한 뒤 orca.exe를 실행하는 `~/.local/bin/orca`를 설치한다. Orca 어댑터를 WSL에서 쓰려면 필요하다.

## Python 제어기

초기 버전에는 포함하지 않는다.

Markdown 하네스와 통신 어댑터로 충분하다. 다음이 필요해질 때 별도 제어기를 추가한다.

- 여러 작업의 병렬 상태 관리
- 자동 타임아웃과 재시도
- pane 자동 복구
- 상태 전이 기계 검증
- 이벤트 로그와 대시보드
