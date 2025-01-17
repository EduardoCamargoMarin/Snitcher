
$scriptUrl = "https://raw.githubusercontent.com/EduardoCamargoMarin/Snitcher/main/Snitcher.ps1"
$importData = "https://raw.githubusercontent.com/EduardoCamargoMarin/Snitcher/main/Devices.xlsx"
$iconUrl = "https://raw.githubusercontent.com/EduardoCamargoMarin/Snitcher/main/SnitcherIcon" 


$installDir = "C:\Network APK\Snitcher"


if (-not (Test-Path -Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}


Invoke-WebRequest -Uri $scriptUrl -OutFile "$installDir\Snitcher.ps1"

Invoke-WebRequest -Uri $iconUrl -OutFile "$installDir\snitcher.ico"

Invoke-WebRequest -Uri $importData -OutFile "$installDir\Devices.xlsx"

$desktop = [System.Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path -Path $desktop -ChildPath "Snitcher.lnk"


$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installDir\snitcher.ps1`""
$shortcut.IconLocation = "$installDir\snitcher.ico"
$shortcut.Save()



if (-not (Get-Module -Name ImportExcel -ListAvailable)) {
    Write-Host "O módulo ImportExcel não foi encontrado. Instalando..."
    Install-Module -Name ImportExcel -Force -Scope CurrentUser
} else {
    Write-Host "O módulo ImportExcel já está instalado."
}

Write-Host "Instalação concluída. O atalho foi criado na área de trabalho."
Pause
