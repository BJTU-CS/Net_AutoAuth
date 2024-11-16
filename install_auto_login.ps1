# 获取当前用户的用户名
$userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]

# 定义源文件路径
$sourceFile = Join-Path -Path (Get-Location) -ChildPath "LoginScript.ps1"
# 定义目标文件路径
$userFolder = "C:\Users\$userName"
$startupFolder = "C:\Users\$userName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
$ps1File = Join-Path -Path $userFolder -ChildPath "LoginScript.ps1"
$vbsFile = Join-Path -Path $startupFolder -ChildPath "RunLoginScript.vbs"

# 检查源文件是否存在
if (-Not (Test-Path -Path $sourceFile)) {
    Write-Host "LoginScript.ps1 not found in the current directory." -ForegroundColor Red
    exit
}

# 复制 PowerShell 脚本到启动文件夹
Copy-Item -Path $sourceFile -Destination $ps1File -Force

# PowerShell 脚本内容
$vbScriptContent = @"
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$ps1File""", 0
Set objShell = Nothing
"@

# 将 VBScript 文件内容写入到目标文件
Set-Content -Path $vbsFile -Value $vbScriptContent

Write-Host "LoginScript.ps1 and RunLoginScript.vbs have been successfully created in the user folder and startup folder." -ForegroundColor Green
