$devices = @(

"8.8.8.8",
 
"1.1.1.1",
 
"google.com", 

"192.168.10.10"

)

# Telegram Messenger
$botToken = "7841399165:AAEpYmUs2A6e2kvYNvTS08x8WQAF_Dcw_aY" # Invalid public BotToken - This is an example
$chatID = "7824317682" # Invalid public ChatID - This is an Example

# Send message with UTF-08 decode
function Send-TelegramMessage {
    param (
        [string]$botToken,
        [string]$chatId,
        [string]$message
    )

    # It makes sure that the sent message is UTF-08
    $utf8Message = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::UTF8.GetBytes($message))

    # Remove special characters
    $utf8Message = $utf8Message -replace '[^\x00-\x7F]+', ''

    $url = "https://api.telegram.org/bot$botToken/sendMessage"
    $body = @{
        chat_id = $chatId
        text    = $utf8Message
    }

    # Request HTTP POST
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
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "================================================"
    Write-Host "      Monitoramento da rede   $timestamp    "
    Write-Host "================================================"

    foreach ($device in $devices) {
        $testResult = Test-Connection -ComputerName $device -Count 1 -Quiet
        
        if ($testResult) {
            Write-Host " [ $device ] está online" -ForegroundColor Green
        } else {
            Write-Host " [ $device ] está offline" -ForegroundColor Red

            # Envia mensagem para o Telegram quando o dispositivo está offline
            $message = "Alerta! A Central de XPTO está offline."
            Send-TelegramMessage -botToken $botToken -chatId $chatID -message $message
        }
    }

    Start-Sleep -Seconds 2 # Retry test
}
