#!/usr/bin/env bash
# Install a WSL `orca` command that works around an orca.exe crash when
# launched through WSL interop.
#
# Problem: WSL interop always injects the Linux-format PATH into Windows
# child processes, which already carry the Windows `Path`. orca.exe builds a
# case-insensitive dictionary from the environment block and dies on the
# duplicate key ("항목이 이미 추가되었습니다 ... 'Path' / 'PATH'"). Nothing on
# the WSL side (env -u PATH, env -i, cmd.exe) can prevent the injection, so
# the fix must run inside the Windows process: a PowerShell shim removes the
# duplicate before starting orca.exe.
#
# Requires the Orca-managed WSL launcher (~/.local/bin/orca-ide) to already
# exist; the orca.exe path is read from it at run time so Orca updates keep
# working.
set -euo pipefail

ORCA_IDE="${HOME}/.local/bin/orca-ide"
if [[ ! -f "${ORCA_IDE}" ]]; then
  echo "ERROR: ${ORCA_IDE} not found. Install the Orca WSL CLI from the Orca app first." >&2
  exit 1
fi

BIN_DIR="${HOME}/.local/bin"
SHIM_DIR="${HOME}/.local/share/orca-wsl-fix"
mkdir -p "${BIN_DIR}" "${SHIM_DIR}"

cat > "${SHIM_DIR}/dedupe.ps1" <<'PS1'
# Remove the WSL-injected PATH so orca.exe sees one case-insensitive Path key.
param(
  [Parameter(Mandatory=$true)]
  [string]$OrcaLauncher,

  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$ForwardArgs
)

$winPath = "$env:SystemRoot\System32;$env:SystemRoot"
# The block holds two entries differing only in case; each call removes one.
[Environment]::SetEnvironmentVariable('PATH', $null)
[Environment]::SetEnvironmentVariable('PATH', $null)
[Environment]::SetEnvironmentVariable('Path', $winPath)

& $OrcaLauncher @ForwardArgs
if ($null -eq $LASTEXITCODE) { exit 0 }
exit $LASTEXITCODE
PS1

cat > "${BIN_DIR}/orca" <<'SH'
#!/usr/bin/env bash
# WSL `orca` wrapper: routes through dedupe.ps1 because WSL interop injects a
# second PATH key that crashes orca.exe. See install-orca-wsl-cli.sh.
set -euo pipefail

ORCA_IDE="${HOME}/.local/bin/orca-ide"
DEDUPE="${HOME}/.local/share/orca-wsl-fix/dedupe.ps1"

ORCA_EXE="$(sed -n "s/^ORCA_WIN_LAUNCHER='\(.*\)'$/\1/p" "${ORCA_IDE}" | head -1)"
if [[ -z "${ORCA_EXE}" ]]; then
  echo "ERROR: could not read ORCA_WIN_LAUNCHER from ${ORCA_IDE}" >&2
  exit 1
fi

if command -v powershell.exe >/dev/null 2>&1; then
  POWERSHELL=powershell.exe
elif [[ -x /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe ]]; then
  POWERSHELL=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
else
  echo "ERROR: powershell.exe not found (Windows interop required)" >&2
  exit 1
fi

exec "${POWERSHELL}" -NoProfile -ExecutionPolicy Bypass \
  -File "$(wslpath -w "${DEDUPE}")" "${ORCA_EXE}" "$@"
SH
chmod +x "${BIN_DIR}/orca"

"${BIN_DIR}/orca" status --json >/dev/null
echo "installed: ${BIN_DIR}/orca (verified against the running Orca runtime)"
