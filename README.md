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

## Pico Herdr

`pico-herdr`는 현재 프로젝트를 기준으로 Herdr named session과 tab을 여는 전역 셸 유틸이다. 짧은 명령은 `ph`다.

전역 설치:

```bash
install -m 755 scripts/pico-herdr.sh ~/.local/bin/pico-herdr
ln -sfn pico-herdr ~/.local/bin/ph
```

`~/.local/bin`이 `PATH`에 포함되어 있어야 한다.

현재 디렉터리가 Git 저장소 안이면 저장소 루트와 디렉터리 이름을 프로젝트 경로 및 Herdr session 이름으로 사용한다.

```bash
# 현재 프로젝트 전용 Herdr session 생성 또는 접속
ph create

# 현재 workspace에 claude 제목의 tab 생성 또는 포커스
ph open claude

# 해석된 프로젝트 경로와 session 이름 확인
ph info
```

`ph open <title>`은 현재 workspace에 해당 제목의 tab을 만든다. 같은 제목의 tab이 이미 있으면 새로 만들지 않고 기존 tab을 포커스한다. 일반 셸에서 실행하면 session의 첫 workspace를 사용한다.

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

## Windows Orca + WSL 알려진 문제

Orca 앱은 Windows에서 실행하고 저장소와 에이전트 셸은 WSL에서 실행하는 구성에서 다음 문제가 확인됐다.

- WSL interop으로 생성된 Windows 프로세스 환경 블록에 `PATH`와 `Path`가 함께 존재할 수 있다.
- Windows PowerShell과 .NET은 환경변수 이름을 대소문자 구분 없이 처리한다. 두 키를 사전으로 변환할 때 중복 키 예외가 발생하면 `orca-ide`가 명령을 처리하기 전에 종료된다.
- PowerShell의 대소문자 구분 문자열 연산자는 Windows `Env:` 공급자와 프로세스 환경변수 이름 처리 방식을 바꾸지 않는다.
- Windows Orca가 설치한 WSL용 `orca-ide`도 PowerShell bridge를 사용하지만, 환경 블록의 중복 키가 정규화되지 않은 버전에서는 같은 오류가 발생할 수 있다.
- WSL 현재 디렉터리가 Windows 쪽에 UNC 경로로 전달되면 이전 Orca 버전에서 현재 worktree 선택이 실패하거나 Windows 디렉터리로 대체될 수 있다.
- Linux 외부 셸에서 bare `orca`는 Orca CLI가 아니라 GNOME Orca 스크린리더일 수 있다. 공식 WSL 명령 이름은 `orca-ide`다.

이 문제는 Windows Orca와 WSL 사이의 프로세스 실행 경계에서 발생하며, 이 저장소는 별도 Orca CLI 우회 설치 스크립트를 제공하지 않는다.

## Python 제어기

초기 버전에는 포함하지 않는다.

Markdown 하네스와 통신 어댑터로 충분하다. 다음이 필요해질 때 별도 제어기를 추가한다.

- 여러 작업의 병렬 상태 관리
- 자동 타임아웃과 재시도
- pane 자동 복구
- 상태 전이 기계 검증
- 이벤트 로그와 대시보드
