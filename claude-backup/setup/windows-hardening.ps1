<#
    Windows 호스트 안전장치 일괄 적용 — 관리자 PowerShell에서 1회 실행.

        Set-ExecutionPolicy -Scope Process Bypass -Force
        .\windows-hardening.ps1

    적용 항목
      1. C: 시스템 보호(복원 지점) 켜기 + 디스크 10% 할당
      2. PowerShell 스크립트 블록 로깅 켜기
      3. 프로세스 생성 감사 + 명령줄 기록 켜기
      4. 현재 상태 점검 출력

    NVMe SSD는 TRIM 때문에 삭제 후 복구가 사실상 불가능하다.
    사후 복구가 아니라 사전 스냅샷만이 유일한 방어선이다.
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

function Step($n, $msg) { Write-Host "`n[$n] $msg" -ForegroundColor Cyan }
function OK($msg)       { Write-Host "    OK  $msg" -ForegroundColor Green }
function Warn($msg)     { Write-Host "    !!  $msg" -ForegroundColor Yellow }

# ── 1. 시스템 복원 지점 ──
Step 1 "C: 시스템 보호(복원 지점) 활성화"
try {
    Enable-ComputerRestore -Drive "C:\"
    # 디스크의 10%를 복원 지점에 할당
    vssadmin resize shadowstorage /for=C: /on=C: /maxsize=10% | Out-Null
    Checkpoint-Computer -Description "hardening-baseline" -RestorePointType MODIFY_SETTINGS
    OK "복원 지점 활성화 + 기준 스냅샷 생성 (디스크 10% 할당)"
} catch {
    Warn "실패: $($_.Exception.Message)"
    Warn "수동: Win+R -> sysdm.cpl -> 시스템 보호 탭 -> C: 선택 -> 구성"
}

# ── 2. PowerShell 스크립트 블록 로깅 ──
Step 2 "PowerShell 스크립트 블록 로깅"
$psLog = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
New-Item -Path $psLog -Force | Out-Null
Set-ItemProperty -Path $psLog -Name 'EnableScriptBlockLogging' -Value 1 -Type DWord
OK "실행된 모든 PowerShell 스크립트가 이벤트로그에 보존됨 (이벤트 ID 4104)"

# ── 3. 프로세스 생성 감사 + 명령줄 기록 ──
Step 3 "프로세스 생성 감사 및 명령줄 기록"
auditpol /set /subcategory:"Process Creation" /success:enable /failure:enable | Out-Null
$audit = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit'
New-Item -Path $audit -Force | Out-Null
Set-ItemProperty -Path $audit -Name 'ProcessCreationIncludeCmdLine_Enabled' -Value 1 -Type DWord
OK "실행된 명령줄이 이벤트로그에 보존됨 (이벤트 ID 4688)"

# ── 4. 상태 점검 ──
Step 4 "현재 상태 점검"

$restore = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
if ($restore) { OK "복원 지점 $($restore.Count)개 존재" } else { Warn "복원 지점 없음" }

$oneDrive = Test-Path "$env:USERPROFILE\OneDrive"
$gDrive   = Test-Path "G:\My Drive"
if ($oneDrive -or $gDrive) {
    OK "클라우드 동기화 폴더 감지됨 ($(if($oneDrive){'OneDrive '})$(if($gDrive){'Google Drive'}))"
} else {
    Warn "클라우드 동기화 폴더가 없습니다 - 바탕화면/문서 동기화를 켜세요"
}

$wsl = (wsl --status 2>&1 | Out-String)
if ($wsl -match 'WSL|기본') { OK "WSL 설치됨" } else { Warn "WSL 미설치 - 'wsl --install' 실행 후 재부팅" }

Write-Host "`n다음 단계: WSL 안에서 setup-wsl.sh 실행" -ForegroundColor Cyan
Write-Host "  wsl"
Write-Host "  git clone https://github.com/v2sion/web1.git ~/web1"
Write-Host "  bash ~/web1/claude-backup/setup/setup-wsl.sh`n"
