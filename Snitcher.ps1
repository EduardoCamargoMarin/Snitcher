# Log Directory
$logDir = "C:\Network Diagnostics\Snitcher\Logs"

# It Creates a separated log each day
if (!(Test-Path -Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$logFile = Join-Path -Path $logDir -ChildPath "Log_$(Get-Date -Format 'dd-MM-yyyy').log"

function Log-Event {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFile -Value "$logEntry`r`n"
}

# Path to Excel file with devices
$excelFilePath = "C:\Network APK\Snitcher\Devices.xlsx"
if (!(Test-Path $excelFilePath)) {
    Write-Host "Arquivo de dispositivos não encontrado: $excelFilePath" -ForegroundColor Red
    Pause
    exit
}

try {
    Import-Module ImportExcel -ErrorAction Stop
    $devices = Import-Excel -Path $excelFilePath
} catch {
    Write-Host "Erro ao importar o módulo ImportExcel ou ler o arquivo: $_" -ForegroundColor Red
    Pause
    exit
}

# Data storage of the last verification
$lastChecked = @{}
$currentStatuses = @{}

# Telegram Messenger
$botToken = "7841399165:AAEpYmUs2A6e2kvYNvTS08x8WQAF_Dcw_aY"
$chatID = "7824317682"

# Send message with UTF-8 decode
function Send-TelegramMessage {
    param (
        [string]$botToken,
        [string]$chatId,
        [string]$message
    )

    $utf8Message = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($message))
    $utf8Message = $utf8Message -replace '[^\x00-\x7F]+', ''

    $url = "https://api.telegram.org/bot$botToken/sendMessage"
    $body = @{
        chat_id = $chatId
        text    = $utf8Message
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -ContentType "application/json" -Body ($body | ConvertTo-Json -Depth 10)
        Write-Host "Mensagem enviada para a Central!" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao enviar mensagem para o Telegram: $_" -ForegroundColor Red
    }
}

# Remote Monitoring
while ($true) {
    Clear-Host
    $currentTime = Get-Date
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "================================================"
    Write-Host "      Monitoramento da rede   $timestamp    "
    Write-Host "================================================"

    foreach ($device in $devices) {

         # Check if NAME, IP and INTERVAL has data

        if (-not $device.NAME -or -not $device.IP -or -not $device.INTERVAL) {
        Write-Host "Dispositivo inválido detectado. Nome: $($device.NAME), IP: $($device.IP), Intervalo: $($device.INTERVAL)" -ForegroundColor Yellow
        continue
    }


        $ip = $device.IP
        $interval = $device.Interval
        $locationName = $device.NAME

        if (-not $lastChecked.ContainsKey($ip)) {
            $lastChecked[$ip] = (Get-Date).AddSeconds(-$interval)
        }

        if (($currentTime - $lastChecked[$ip]).TotalSeconds -ge $interval) {
            try {
                $testResult = Test-Connection -ComputerName $ip -Count 1 -Quiet
            } catch {
                $errorMsg = "Erro ao testar conexão com $ip : $($_.Exception.Message)"
                Write-Host $errorMsg -ForegroundColor Yellow
                Log-Event -message $errorMsg
                continue
            }

            # Retrieve previous status or set to unknown if not exists
            $previousStatus = $currentStatuses[$ip]
            $currentStatuses[$ip] = $testResult

            # Log status
            if ($testResult) {
                Write-Host " [ $locationName ] está online" -ForegroundColor Green
                Log-Event -message "Dispositivo $ip está online."
            } else {
                Write-Host " [ $locationName ] está offline" -ForegroundColor Red
                Log-Event -message "Dispositivo $ip está offline."
            }

            # Send alert if status changed
            if ($previousStatus -ne $testResult) {
                $statusText = if ($testResult) { "ONLINE" } else { "OFFLINE" }
                $message = " $locationName mudou de status para $statusText."
                Send-TelegramMessage -botToken $botToken -chatId $chatID -message $message
            }

            # Update the last checked time
            $lastChecked[$ip] = $currentTime
        }
    }
    Start-Sleep -Seconds 1 # Retry test
}
