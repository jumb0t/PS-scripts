# PowerShell Скрипт для оптимизации производительности Windows 11

# Запуск PowerShell с правами администратора обязателен для внесения системных изменений
# Убедитесь, что вы запускаете этот скрипт от имени администратора

# Функция для установки плана электропитания "Высокая производительность"
function Set-HighPerformancePowerPlan {
    Write-Output "Установка плана электропитания 'Высокая производительность'..."
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
    Write-Output "План электропитания установлен."
}

# Функция для отключения ненужных служб
function Disable-UnnecessaryServices {
    Write-Output "Отключение ненужных служб..."

    # Список служб для отключения
    $services = @(
        "Spooler",         # Печать
        "Fax",             # Факс
        "XblGameSave",     # Служба сохранения игр Xbox
        "WMPNetworkSvc",   # Служба сетевого медиасервера Windows Media Player
        "RetailDemo",      # Демонстрационная служба
        "WSearch"          # Служба поиска Windows (отключение может замедлить поиск)
    )

    foreach ($service in $services) {
        try {
            Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
            Stop-Service -Name $service -Force -ErrorAction Stop
            Write-Output "Служба '$service' отключена."
        } catch {
            Write-Output "Не удалось отключить службу '$service'. Возможно, она не установлена или требуется."
        }
    }

    Write-Output "Отключение служб завершено."
}

# Функция для отключения визуальных эффектов
function Disable-VisualEffects {
    Write-Output "Отключение визуальных эффектов для повышения производительности..."
    
    # Установка параметра производительности для максимальной производительности
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    Set-ItemProperty -Path $registryPath -Name "VisualFXSetting" -Value 2

    Write-Output "Визуальные эффекты отключены."
}

# Функция для очистки диска
function Clean-Disk {
    Write-Output "Очистка диска от временных файлов и мусора..."

    # Очистка временных файлов
    Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Очистка корзины
    Clear-RecycleBin -Force

    Write-Output "Очистка диска завершена."
}

# Функция для отключения индексации поиска (может повысить производительность диска)
function Disable-SearchIndexing {
    Write-Output "Отключение индексации поиска..."

    Set-Service -Name "WSearch" -StartupType Disabled
    Stop-Service -Name "WSearch" -Force

    Write-Output "Индексация поиска отключена."
}

# Функция для оптимизации настроек автозагрузки
function Optimize-Autostart {
    Write-Output "Оптимизация программ автозагрузки..."

    # Получение списка программ автозагрузки
    $startupApps = Get-CimInstance -ClassName Win32_StartupCommand

    foreach ($app in $startupApps) {
        # Пример: отключение определённых программ автозагрузки
        # Здесь можно добавить условия для отключения ненужных приложений
        # Например:
        if ($app.Name -like "*OneDrive*") {
            Disable-Item -Path $app.Location -ErrorAction SilentlyContinue
            Write-Output "Отключено автозапуск приложения: $($app.Name)"
        }
    }

    Write-Output "Оптимизация автозагрузки завершена."
}

# Главная функция для выполнения всех оптимизаций
function Optimize-Performance {
    Set-HighPerformancePowerPlan
    Disable-UnnecessaryServices
    Disable-VisualEffects
    Clean-Disk
    Disable-SearchIndexing
    Optimize-Autostart

    Write-Output "Оптимизация производительности завершена. Рекомендуется перезагрузить компьютер для применения изменений."
}

# Вызов главной функции
Optimize-Performance
