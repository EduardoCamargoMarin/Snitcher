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

$devices = @(
    @{ IP = "8.8.8.9"; Interval = 5 }, # invalid IP for offline testing
    @{ IP = "1.1.1.1"; Interval = 10 },
    @{ IP = "google.com"; Interval = 15 },
    @{ IP = "156.59.238.9"; Interval = 20 }
)

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
        $ip = $device.IP
        $interval = $device.Interval

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
                Write-Host " [ $ip ] está online" -ForegroundColor Green
                Log-Event -message "Dispositivo $ip está online."
            } else {
                Write-Host " [ $ip ] está offline" -ForegroundColor Red
                Log-Event -message "Dispositivo $ip está offline."
            }

            # Send alert if status changed
            if ($previousStatus -ne $testResult) {
                $statusText = if ($testResult) { "online" } else { "offline" }
                $message = "Alerta! O dispositivo $ip mudou de status para $statusText."
                Send-TelegramMessage -botToken $botToken -chatId $chatID -message $message
            }

            # Update the last checked time
            $lastChecked[$ip] = $currentTime
        }
    }
    Start-Sleep -Seconds 1 # Retry test
}
