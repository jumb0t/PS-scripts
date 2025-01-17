# Отключение Windows Defender через PowerShell

# Запуск PowerShell с правами администратора
if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Этот скрипт должен быть запущен от имени администратора."
    exit
}

# Отключение реального времени защиты
Set-MpPreference -DisableRealtimeMonitoring $true

# Отключение других компонентов Windows Defender
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableOnAccessProtection $true
Set-MpPreference -DisableScanningNetworkFiles $true
Set-MpPreference -DisableScriptScanning $true

# Остановка и отключение службы Windows Defender
Stop-Service -Name "WinDefend" -Force
Set-Service -Name "WinDefend" -StartupType Disabled

# Отключение планировщика задач Windows Defender
Unregister-ScheduledTask -TaskName "Windows Defender Scheduled Scan" -TaskPath "\Microsoft\Windows\Windows Defender\" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "Windows Defender Cache Maintenance" -TaskPath "\Microsoft\Windows\Windows Defender\" -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "Windows Defender Cleanup" -TaskPath "\Microsoft\Windows\Windows Defender\" -ErrorAction SilentlyContinue

Write-Output "Windows Defender был успешно отключен."
