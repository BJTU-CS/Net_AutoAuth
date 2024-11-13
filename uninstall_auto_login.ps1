# 获取当前用户的用户名
$userName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1]

# 定义目标文件路径
$startupFolder = "C:\Users\$userName\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
$targetFile = Join-Path -Path $startupFolder -ChildPath "LoginScript.ps1"
$vbsFile = Join-Path -Path $startupFolder -ChildPath "RunLoginScript.vbs"

# 检查并删除 PowerShell 脚本文件
if (Test-Path -Path $targetFile) {
    Remove-Item -Path $targetFile -Force
    Write-Host "LoginScript.ps1 has been successfully removed from the startup folder." -ForegroundColor Green
} else {
    Write-Host "LoginScript.ps1 not found in the startup folder." -ForegroundColor Yellow
}

# 检查并删除 VBScript 文件
if (Test-Path -Path $vbsFile) {
    Remove-Item -Path $vbsFile -Force
    Write-Host "RunLoginScript.vbs has been successfully removed from the startup folder." -ForegroundColor Green
} else {
    Write-Host "RunLoginScript.vbs not found in the startup folder." -ForegroundColor Yellow
}
