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
    @{ NAME = "Central A-SP"; IP = "187.87.247.83"; Interval = 5 }, # Random Public IP for Testing
    @{ NAME = "Central B-SP"; IP = "1.1.1.1"; Interval = 10 }, # CloudFlare
    @{ NAME = "Central C-SP"; IP = "8.8.8.8"; Interval = 15 }, # Google
    @{ NAME = "Central D-SP"; IP = "177.170.209.44"; Interval = 20 } # Random Public IP for Testing
)

# Data storage of the last verification
$lastChecked = @{}
$currentStatuses = @{}

# Telegram Messenger
$botToken = "<INSIRA O TOKEN>"
$chatID = "<CHAT ID>"

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
