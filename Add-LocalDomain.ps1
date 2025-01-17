# Путь к файлу hosts
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

# Резервное копирование файла hosts
$backupPath = "$hostsPath.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"
Copy-Item -Path $hostsPath -Destination $backupPath -Force
Write-Output "Резервная копия создана: $backupPath"

# Домен и IP-адрес
$domain ="proxy"
$ip = "127.0.0.1"

# Чтение текущего содержимого файла hosts
$hostsContent = Get-Content -Path $hostsPath

# Проверка, существует ли уже запись для домена
$entryExists = $hostsContent | Select-String -Pattern "\b$domain\b"

if ($entryExists) {
    Write-Output "Запись для '$domain' уже существует в файле hosts."
} else {
    # Добавление новой записи
    "$ip`t$domain" | Out-File -FilePath $hostsPath -Encoding ascii -Append
    Write-Output "Запись '$domain' -> '$ip' добавлена в файл hosts."
}

# Очистка DNS-кэша
Clear-DnsClientCache
Write-Output "DNS-кэш очищен."
