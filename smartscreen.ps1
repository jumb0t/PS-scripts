# Отключение Microsoft Defender Antivirus и SmartScreen на Windows 11
# Запускать этот скрипт необходимо с правами администратора

# Проверка запуска скрипта от имени администратора
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "Этот скрипт необходимо запускать от имени администратора."
    exit
}

# Функция для отключения службы
function Disable-ServiceIfExists {
    param (
        [string]$ServiceName
    )
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        try {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $ServiceName -StartupType Disabled
            Write-Output "Служба '$ServiceName' отключена."
        } catch {
            Write-Warning "Не удалось отключить службу '$ServiceName'."
        }
    } else {
        Write-Output "Служба '$ServiceName' не найдена."
    }
}

# Отключение Microsoft Defender Antivirus
Write-Output "Отключение Microsoft Defender Antivirus..."

# Отключение защиты в реальном времени
try {
    Set-MpPreference -DisableRealtimeMonitoring $true
    Write-Output "Защита в реальном времени отключена."
} catch {
    Write-Warning "Не удалось отключить защиту в реальном времени. Возможно, установлены политики групповой политики."
}

# Отключение сканирования по расписанию
try {
    Set-MpPreference -DisableScheduledScanning $true
    Write-Output "Сканирование по расписанию отключено."
} catch {
    Write-Warning "Не удалось отключить сканирование по расписанию."
}

# Отключение службы Windows Defender
Disable-ServiceIfExists -ServiceName "WinDefend"

# Отключение Defender через реестр (опционально)
Write-Output "Отключение Defender через реестр..."
try {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -PropertyType DWord -Value 1 -Force | Out-Null
    Write-Output "Параметр 'DisableAntiSpyware' установлен."
} catch {
    Write-Warning "Не удалось установить параметр 'DisableAntiSpyware'."
}

# Отключение SmartScreen
Write-Output "Отключение SmartScreen..."

# Отключение SmartScreen через реестр для всех пользователей
try {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -PropertyType String -Value "Off" -Force | Out-Null
    Write-Output "SmartScreen отключен для всех пользователей."
} catch {
    Write-Warning "Не удалось отключить SmartScreen для всех пользователей."
}

# Отключение SmartScreen через реестр для текущего пользователя
try {
    New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "SmartScreenEnabled" -PropertyType String -Value "Off" -Force | Out-Null
    Write-Output "SmartScreen отключен для текущего пользователя."
} catch {
    Write-Warning "Не удалось отключить SmartScreen для текущего пользователя."
}

# Отключение SmartScreen для приложений Windows Store (опционально)
Write-Output "Отключение SmartScreen для приложений Windows Store..."
try {
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" -Name "EnableWebContentEvaluation" -PropertyType DWord -Value 0 -Force | Out-Null
    Write-Output "SmartScreen для приложений Windows Store отключен."
} catch {
    Write-Warning "Не удалось отключить SmartScreen для приложений Windows Store."
}

# Применение изменений
Write-Output "Применение изменений..."

# Перезапуск проводника для применения некоторых изменений
try {
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Output "Проводник перезапущен."
} catch {
    Write-Warning "Не удалось перезапустить проводник."
}

# Рекомендуемая перезагрузка системы
Write-Output "Отключение Defender и SmartScreen завершено. Рекомендуется перезагрузить систему для полного применения изменений."

# Запрос на перезагрузку системы
$reboot = Read-Host "Перезагрузить систему сейчас? (Y/N)"
if ($reboot -eq 'Y' -or $reboot -eq 'y') {
    Restart-Computer -Force
} else {
    Write-Output "Перезагрузка системы откладывается. Пожалуйста, перезагрузите систему вручную для применения всех изменений."
}
