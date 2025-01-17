<#
.SYNOPSIS
    Оптимизирует Windows 11 для использования через RDP при низкой скорости интернет-соединения.

.DESCRIPTION
    Этот скрипт отключает телеметрию, анимации, визуальные эффекты и настраивает параметры RDP для максимальной производительности.
    Он также оптимизирует системные настройки для работы при низкой пропускной способности сети.

.NOTES
    Скрипт должен быть запущен с правами администратора.
#>

# Проверка запуска скрипта от имени администратора
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Warning "Этот скрипт необходимо запускать от имени администратора."
    exit
}

# Функция для отключения службы, если она существует
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

# Функция для отключения планировочных задач, если они существуют
function Disable-ScheduledTaskIfExists {
    param (
        [string]$TaskPath
    )
    try {
        if (Get-ScheduledTask -TaskPath $TaskPath -ErrorAction SilentlyContinue) {
            Disable-ScheduledTask -TaskPath $TaskPath -ErrorAction SilentlyContinue
            Write-Output "Планировочная задача '$TaskPath' отключена."
        }
    } catch {
        Write-Warning "Не удалось отключить планировочную задачу '$TaskPath'."
    }
}

# Отключение телеметрии и связанных служб
Write-Output "Отключение телеметрии и связанных служб..."
$telemetryServices = @(
    "DiagTrack",                # Служба диагностики
    "dmwappushservice",         # Служба отправки приложений
    "dmwappushsvc",             # Альтернативное имя службы отправки приложений
    "ConnectedUserExperiencesHost", # Служба пользовательского опыта
    "dmzSvc"                    # Служба DMZ
)

foreach ($service in $telemetryServices) {
    Disable-ServiceIfExists -ServiceName $service
}

# Отключение планировочных задач телеметрии
$telemetryTasks = @(
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\DeliveryOptimization\DeliveryOptimization",
    "\Microsoft\Windows\FeedbackHub\FeedbackNotification",
    "\Microsoft\Windows\NetTrace\GatherNetworkInfo",
    "\Microsoft\Windows\Shell\FamilySafetyMonitor",
    "\Microsoft\Windows\TaskScheduler\UploadTask",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
    "\Microsoft\Windows\Windows Error Reporting\SvcRestart",
    "\Microsoft\Windows\Windows Search\Windows Search",
    "\Microsoft\Windows\Workday\Workday Task"
)

foreach ($task in $telemetryTasks) {
    Disable-ScheduledTaskIfExists -TaskPath $task
}

# Отключение визуальных эффектов и анимаций
Write-Output "Отключение визуальных эффектов и анимаций..."

# Отключение анимаций окон
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String -Force

# Отключение визуальных эффектов через реестр
$visualEffectsSettings = @{
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" = @{
        "VisualFXSetting" = 2
    }
    "HKCU:\Control Panel\Desktop" = @{
        "WindowMetrics" = @{
            "MinAnimate" = "0"
        }
        "DragFullWindows" = "0"
    }
    "HKCU:\Control Panel\Desktop\WindowMetrics" = @{
        "MinAnimate" = "0"
    }
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" = @{
        "TaskbarAnimations" = 0
        "ListviewAlphaSelect" = 0
        "MenuShowDelay" = 0
        "EnableBalloonTips" = 0
        "UserPreferencesMask" = [byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00) # Отключение анимаций
    }
    "HKCU:\Software\Microsoft\Windows\DWM" = @{
        "AnimateWindows" = 0
        "EnableAeroPeek" = 0
        "EnableWindowColorization" = 0
        "ColorizationColor" = 0x00FFFFFF
    }
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" = @{
        "EnableTransparency" = 0
        "EnableAcrylic" = 0
        "EnableFontSmoothing" = 0
        "ColorPrevalence" = 0
    }
}

foreach ($path in $visualEffectsSettings.Keys) {
    foreach ($property in $visualEffectsSettings[$path].Keys) {
        try {
            Set-ItemProperty -Path $path -Name $property -Value $visualEffectsSettings[$path][$property] -Force
            Write-Output "Установлено свойство '$property' в '$path'."
        } catch {
            Write-Warning "Не удалось установить свойство '$property' в '$path'."
        }
    }
}

# Дополнительные настройки для отключения визуальных эффектов
# Отключение теней окон
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableShadow" -Value "0" -Type DWord -Force

# Отключение фонового изображения рабочего стола
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value "" -Type String -Force

# Отключение эффектов Aero
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value "0" -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroGlass" -Value "0" -Type DWord -Force

# Отключение анимации окон при открытии/закрытии
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Type String -Force

# Отключение анимации меню
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Type String -Force

# Отключение эффекта мыши при наведении на элементы
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -Force

# Отключение прозрачности
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value "0" -Type DWord -Force

# Оптимизация параметров RDP
Write-Output "Оптимизация параметров RDP..."

# Установка максимальной производительности RDP через реестр
$rdpSettings = @{
    "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" = @{
        "ColorDepth" = 24                      # Установка глубины цвета до 24 бит
        "DesktopComposition" = 0               # Отключение композитных эффектов
        "AllowFontSmoothing" = 0               # Отключение сглаживания шрифтов
        "AllowDesktopComposition" = 0          # Отключение композитных эффектов рабочего стола
        "DisableThemes" = 1                    # Отключение тем
        "BitmapCaching" = 1                    # Включение кэширования битмапов
        "Compression" = 1                      # Включение компрессии данных
        "SessionBPP" = 24                      # Глубина цвета сеанса
    }
}

foreach ($path in $rdpSettings.Keys) {
    foreach ($property in $rdpSettings[$path].Keys) {
        try {
            Set-ItemProperty -Path $path -Name $property -Value $rdpSettings[$path][$property] -Force
            Write-Output "Установлено свойство '$property' в '$path'."
        } catch {
            Write-Warning "Не удалось установить свойство '$property' в '$path'."
        }
    }
}

# Отключение дополнительных визуальных эффектов через Групповую Политику (если применимо)
Write-Output "Отключение дополнительных визуальных эффектов через Групповую Политику..."

$gpSettings = @(
    @{
        Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name = "DisableAnimations"
        Value = 1
        Type = "DWord"
    },
    @{
        Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name = "ListviewAlphaSelect"
        Value = 0
        Type = "DWord"
    },
    @{
        Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Name = "TaskbarAnimations"
        Value = 0
        Type = "DWord"
    }
)

foreach ($setting in $gpSettings) {
    try {
        New-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -PropertyType $setting.Type -Force | Out-Null
        Write-Output "Установлено свойство '$($setting.Name)' в '$($setting.Path)'."
    } catch {
        Write-Warning "Не удалось установить свойство '$($setting.Name)' в '$($setting.Path)'."
    }
}

# Отключение ненужных служб для повышения производительности RDP
Write-Output "Отключение ненужных служб для повышения производительности RDP..."
$servicesToDisable = @(
    "WMPNetworkSvc",          # Windows Media Player Network Sharing Service
    "Spooler",                # Print Spooler
    "Fax",                    # Fax
    "XblGameSave",            # Xbox Live Game Save
    "XblAuthManager",         # Xbox Live Authentication Manager
    "WpnService",             # Windows Push Notifications System Service
    "DiagTrack",              # Connected User Experiences and Telemetry
    "dmwappushservice"        # DMW App Push Service
)

foreach ($service in $servicesToDisable) {
    Disable-ServiceIfExists -ServiceName $service
}

# Отключение фоновых приложений и процессов
Write-Output "Отключение фоновых приложений и процессов..."
$backgroundApps = @(
    "Microsoft.YourPhone",
    "Microsoft.People",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsStore",
    "Microsoft.Office.OneNote",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MixedReality.Portal",
    "Microsoft.MSPaint",
    "Microsoft.Office.Sway",
    "Microsoft.Print3D",
    "Microsoft.ScreenSketch",
    "Microsoft.StorePurchaseApp",
    "Microsoft.Wallet",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsCamera",
    "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay"
)

foreach ($app in $backgroundApps) {
    try {
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $app} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        Write-Output "Удалено приложение '$app'."
    } catch {
        Write-Warning "Не удалось удалить приложение '$app'. Возможно, оно отсутствует."
    }
}

# Отключение фоновых обновлений приложений из Microsoft Store
Write-Output "Отключение фоновых обновлений приложений из Microsoft Store..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force

# Отключение фоновой синхронизации
Write-Output "Отключение фоновой синхронизации..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "BackgroundApplicationAdminBoundary" -Value 0 -Type DWord -Force

# Отключение Cortana
Write-Output "Отключение Cortana..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -Force

# Отключение сбора диагностических данных через реестр
Write-Output "Отключение сбора диагностических данных..."
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -PropertyType DWord -Value 0 -Force | Out-Null

# Отключение рекомендаций и рекламы
Write-Output "Отключение рекомендаций и рекламы..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force

# Отключение уведомлений и акций
Write-Output "Отключение уведомлений и акций..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SoftLandingEnabled" -Value 0 -Type DWord -Force

# Очистка автозагрузки ненужных программ
Write-Output "Очистка автозагрузки ненужных программ..."
$startupPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($path in $startupPaths) {
    try {
        if (Test-Path $path) {
            Get-ItemProperty -Path $path | Remove-ItemProperty -Path $path -ErrorAction SilentlyContinue
            Write-Output "Очистка автозагрузки в '$path'."
        }
    } catch {
        Write-Warning "Не удалось очистить автозагрузку в '$path'."
    }
}

# Отключение индексирования поиска для повышения производительности
Write-Output "Отключение индексирования поиска..."
Disable-ServiceIfExists -ServiceName "WSearch"

# Отключение службы Superfetch (SysMain)
Disable-ServiceIfExists -ServiceName "SysMain"

# Отключение службы Windows Update (опционально)
# Disable-ServiceIfExists -ServiceName "wuauserv"

# Перезапуск проводника для применения некоторых изменений
Write-Output "Применение изменений..."
try {
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Output "Проводник перезапущен."
} catch {
    Write-Warning "Не удалось перезапустить проводник."
}

# Очистка кэша и временных файлов
Write-Output "Очистка временных файлов..."
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Настройка параметров производительности
Write-Output "Настройка параметров производительности..."
$performanceOptions = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects",
    "HKCU:\Control Panel\Desktop\WindowMetrics",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
)

foreach ($path in $performanceOptions) {
    if (Test-Path $path) {
        # Отключение всех визуальных эффектов
        Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value "2" -ErrorAction SilentlyContinue
    }
}

# Настройка параметров RDP для максимальной производительности
Write-Output "Настройка параметров RDP для максимальной производительности..."

# Установка глубины цвета RDP до 16 бит для снижения использования трафика
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "SessionBPP" -Value 16 -Type DWord -Force

# Отключение параметров, не влияющих напрямую на производительность, но полезных для оптимизации
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "DesktopComposition" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "AllowFontSmoothing" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "AllowDesktopComposition" -Value 0 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "DisableThemes" -Value 1 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "BitmapCaching" -Value 1 -Type DWord -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "Compression" -Value 1 -Type DWord -Force

# Применение изменений без перезагрузки
Write-Output "Применение всех изменений..."
try {
    Stop-Process -Name explorer -Force
    Start-Process explorer
    Write-Output "Проводник перезапущен для применения изменений."
} catch {
    Write-Warning "Не удалось перезапустить проводник."
}

Write-Output "Оптимизация RDP завершена. Рекомендуется перезагрузить систему для полного применения всех изменений."

# Запрос на перезагрузку системы
$reboot = Read-Host "Перезагрузить систему сейчас? (Y/N)"
if ($reboot -eq 'Y' -or $reboot -eq 'y') {
    Restart-Computer -Force
} else {
    Write-Output "Перезагрузка системы откладывается. Пожалуйста, перезагрузите систему вручную для применения всех изменений."
}

Write-Output "Скрипт завершён."
