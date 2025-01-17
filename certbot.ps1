<#
.SYNOPSIS
    Устанавливает Certbot и получает SSL-сертификат через HTTP-челлендж с использованием standalone метода.

.DESCRIPTION
    Этот скрипт устанавливает Chocolatey (если он ещё не установлен), затем устанавливает Certbot.
    После установки Certbot выполняет команду для получения SSL-сертификата через HTTP-челлендж
    с использованием standalone метода.
    Скрипт также автоматически останавливает IIS (если он запущен) для освобождения порта 80,
    необходимого для прохождения челленджа, и перезапускает его после получения сертификата.

.NOTES
    Скрипт должен быть запущен с правами администратора.
#>

# Проверка запуска скрипта от имени администратора
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Warning "Этот скрипт необходимо запускать от имени администратора."
    exit
}

# Функция для установки Chocolatey
function Install-Chocolatey {
    Write-Output "Проверка наличия Chocolatey..."
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Output "Установка Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        try {
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        } catch {
            Write-Warning "Не удалось загрузить установочный скрипт Chocolatey. Проверьте подключение к интернету и повторите попытку."
            exit
        }
        
        # Проверка успешной установки
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            Write-Output "Chocolatey успешно установлен."
        } else {
            Write-Warning "Не удалось установить Chocolatey. Проверьте подключение к интернету и повторите попытку."
            exit
        }
    } else {
        Write-Output "Chocolatey уже установлен."
    }
}

# Функция для установки Certbot через Chocolatey
function Install-Certbot {
    Write-Output "Установка Certbot через Chocolatey..."
    try {
        choco install certbot -y
    } catch {
        Write-Warning "Не удалось установить Certbot через Chocolatey. Проверьте установку Chocolatey и повторите попытку."
        exit
    }
    
    if (Get-Command certbot -ErrorAction SilentlyContinue) {
        Write-Output "Certbot успешно установлен."
    } else {
        Write-Warning "Не удалось установить Certbot через Chocolatey. Проверьте установку Chocolatey и повторите попытку."
        exit
    }
}

# Функция для остановки службы IIS (если она запущена)
function Stop-IIS {
    Write-Output "Проверка службы IIS..."
    if (Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue) {
        try {
            Stop-Service -Name "W3SVC" -Force
            Write-Output "Служба IIS (W3SVC) остановлена."
        } catch {
            Write-Warning "Не удалось остановить службу IIS (W3SVC). Проверьте, запущены ли другие веб-сервисы."
        }
    } else {
        Write-Output "Служба IIS (W3SVC) не найдена или не установлена."
    }
}

# Функция для запуска службы IIS (если она была остановлена)
function Start-IIS {
    Write-Output "Запуск службы IIS..."
    if (Get-Service -Name "W3SVC" -ErrorAction SilentlyContinue) {
        try {
            Start-Service -Name "W3SVC"
            Write-Output "Служба IIS (W3SVC) запущена."
        } catch {
            Write-Warning "Не удалось запустить службу IIS (W3SVC). Пожалуйста, запустите её вручную."
        }
    } else {
        Write-Output "Служба IIS (W3SVC) не найдена или не установлена."
    }
}

# Функция для получения SSL-сертификата через HTTP-челлендж с использованием standalone метода
function Obtain-Certificate {
    param (
        [string]$Domain,
        [switch]$NoEmail
    )
    
    Write-Output "Получение SSL-сертификата для домена '$Domain' с использованием standalone метода..."
    
    # Проверка и остановка службы IIS
    Stop-IIS
    
    # Формирование команды Certbot
    $certbotCommand = "certbot certonly --standalone --preferred-challenges=http -d $Domain --agree-tos --register-unsafely-without-email"
    
    if ($NoEmail) {
        $certbotCommand += " --no-eff-email"
    } else {
        $email = Read-Host "Введите ваш адрес электронной почты (для уведомлений от Let's Encrypt)"
        $certbotCommand += " --email $email"
    }
    
    # Выполнение команды Certbot
    try {
        Write-Output "Выполнение команды: $certbotCommand"
        Invoke-Expression $certbotCommand
    } catch {
        Write-Warning "Произошла ошибка при выполнении Certbot. Проверьте выходные данные для дополнительной информации."
    }
    
    # Запуск службы IIS обратно
    Start-IIS
    
    # Проверка успешного получения сертификата
    $certPath = "C:\Certbot\live\$Domain"
    if (Test-Path $certPath) {
        Write-Output "Сертификаты успешно получены и находятся по пути: $certPath"
    } else {
        Write-Warning "Не удалось найти сертификаты по пути: $certPath. Проверьте выходные данные Certbot."
    }
}

# Основная часть скрипта

# Установка Chocolatey
Install-Chocolatey

# Установка Certbot
Install-Certbot

# Запрос информации у пользователя
$domain = Read-Host "Введите ваше доменное имя (например, rdp1.ydns.eu)"
$useEmail = Read-Host "Хотите ли вы указать адрес электронной почты? (Y/N)"
$noEmailSwitch = $false

if ($useEmail -eq 'N' -or $useEmail -eq 'n') {
    $noEmailSwitch = $true
}

# Получение сертификата
Obtain-Certificate -Domain $domain -NoEmail:$noEmailSwitch

# Предложение перезагрузить систему
$reboot = Read-Host "Хотите перезагрузить систему сейчас? (Y/N)"
if ($reboot -eq 'Y' -or $reboot -eq 'y') {
    Restart-Computer -Force
} else {
    Write-Output "Перезагрузка системы откладывается. Пожалуйста, перезагрузите систему вручную для применения всех изменений."
}

Write-Output "Скрипт завершён."
