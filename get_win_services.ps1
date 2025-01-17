<#
.SYNOPSIS
    Получает список всех запущенных служб на Windows.

.DESCRIPTION
    Этот скрипт фильтрует службы по статусу "Running" и выводит их имена, статус и тип службы.
    Также предоставляется возможность экспортировать список в файл формата CSV или текстовый файл.

.NOTES
    Скрипт можно запускать как обычным пользователем, так и с правами администратора.
#>

# Функция для вывода разделителя
function Write-Divider {
    Write-Output "------------------------------------------------------------"
}

Write-Divider
Write-Output "Получение списка всех запущенных служб..."
Write-Divider

# Получение списка запущенных служб
$runningServices = Get-Service | Where-Object { $_.Status -eq 'Running' } | Sort-Object DisplayName

# Вывод списка на экран с отформатированным выводом
$runningServices | Format-Table -Property DisplayName, Status, ServiceType -AutoSize

Write-Divider

# Опционально: экспорт списка в CSV-файл
$exportCSV = Read-Host "Хотите экспортировать список в CSV-файл? (Y/N)"
if ($exportCSV -eq 'Y' -or $exportCSV -eq 'y') {
    $csvPath = Read-Host "Введите полный путь для сохранения CSV-файла (например, C:\Users\Username\Desktop\RunningServices.csv)"
    try {
        $runningServices | Select-Object DisplayName, Status, ServiceType | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Output "Список запущенных служб успешно экспортирован в файл: $csvPath"
    } catch {
        Write-Warning "Не удалось экспортировать список в CSV-файл. Проверьте путь и попробуйте снова."
    }
}

# Опционально: экспорт списка в текстовый файл
$exportTXT = Read-Host "Хотите экспортировать список в текстовый файл? (Y/N)"
if ($exportTXT -eq 'Y' -or $exportTXT -eq 'y') {
    $txtPath = Read-Host "Введите полный путь для сохранения текстового файла (например, C:\Users\Username\Desktop\RunningServices.txt)"
    try {
        $runningServices | Select-Object DisplayName, Status, ServiceType | Out-File -FilePath $txtPath -Encoding UTF8
        Write-Output "Список запущенных служб успешно экспортирован в файл: $txtPath"
    } catch {
        Write-Warning "Не удалось экспортировать список в текстовый файл. Проверьте путь и попробуйте снова."
    }
}

Write-Divider
Write-Output "Скрипт завершён."
Write-Divider
