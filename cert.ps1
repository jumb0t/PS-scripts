<#
.SYNOPSIS
    Устанавливает SSL-сертификат для RDP на Windows 11.

.DESCRIPTION
    Этот скрипт ищет установленный сертификат для указанного домена в хранилище LocalMachine\My,
    настраивает его для использования в RDP, обновляет соответствующие настройки реестра и перезапускает службу RDP.

.NOTES
    Скрипт должен быть запущен с правами администратора.
#>

# Проверка запуска скрипта от имени администратора
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Warning "Этот скрипт необходимо запускать от имени администратора."
    exit
}

# Функция для вывода разделителя
function Write-Divider {
    Write-Output "------------------------------------------------------------"
}

Write-Divider
Write-Output "Поиск сертификата для домена 'rdp1.ydns.eu' в хранилище LocalMachine\My..."

# Поиск сертификата по доменному имени (Subject или SAN)
$domain = "proxy.com"

$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {
    ($_.Subject -like "*CN=$domain*") -or
    ($_.Extensions | Where-Object { $_.Oid.FriendlyName -eq "Subject Alternative Name" -and $_.Format(0) -like "*$domain*" })
} | Sort-Object NotAfter -Descending | Select-Object -First 1

if ($null -eq $cert) {
    Write-Warning "Сертификат для домена '$domain' не найден в хранилище LocalMachine\My."
    exit
}

Write-Output "Сертификат найден:"
Write-Output "    Subject: $($cert.Subject)"
Write-Output "    Выдан: $($cert.Issuer)"
Write-Output "    Действителен с: $($cert.NotBefore)"
Write-Output "    Действителен до: $($cert.NotAfter)"
Write-Output "    Отпечаток: $($cert.Thumbprint)"
Write-Divider

# Проверка наличия приватного ключа
if (-not $cert.HasPrivateKey) {
    Write-Warning "Сертификат не содержит приватного ключа. Убедитесь, что сертификат импортирован с приватным ключом."
    exit
}

# Получение отпечатка сертификата
$thumbprint = $cert.Thumbprint
Write-Output "Отпечаток сертификата: $thumbprint"
Write-Divider

# Настройка реестра для использования сертификата в RDP
$rdpRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"

Write-Output "Настройка реестра для использования сертификата в RDP..."

try {
    # Получение текущего значения SSLCertificateSHA1Hash
    $currentThumbprint = (Get-ItemProperty -Path $rdpRegistryPath -Name SSLCertificateSHA1Hash -ErrorAction SilentlyContinue).SSLCertificateSHA1Hash

    if ($currentThumbprint -eq $thumbprint) {
        Write-Output "Сертификат уже установлен для RDP."
    } else {
        # Установка нового отпечатка
        Set-ItemProperty -Path $rdpRegistryPath -Name SSLCertificateSHA1Hash -Value $thumbprint -Force
        Write-Output "Отпечаток сертификата обновлён в реестре."
    }
} catch {
    Write-Warning "Не удалось настроить реестр для RDP. Ошибка: $_"
    exit
}

Write-Divider

# Перезапуск службы RDP для применения изменений
Write-Output "Перезапуск службы Remote Desktop Services..."

try {
    Restart-Service -Name TermService -Force
    Write-Output "Служба Remote Desktop Services успешно перезапущена."
} catch {
    Write-Warning "Не удалось перезапустить службу Remote Desktop Services. Попробуйте перезагрузить систему вручную."
}

Write-Divider

# Проверка установки сертификата
Write-Output "Проверка установки сертификата для RDP..."

$rdpCertThumbprint = (Get-ItemProperty -Path $rdpRegistryPath -Name SSLCertificateSHA1Hash -ErrorAction SilentlyContinue).SSLCertificateSHA1Hash

if ($rdpCertThumbprint -eq $thumbprint) {
    Write-Output "Сертификат успешно установлен для RDP."
} else {
    Write-Warning "Сертификат не был установлен для RDP. Проверьте настройки и повторите попытку."
}

Write-Divider
Write-Output "Скрипт завершён."
