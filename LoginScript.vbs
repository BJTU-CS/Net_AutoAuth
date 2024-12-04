Set objShell = CreateObject("WScript.Shell")
' 获取当前脚本所在目录
Set objFSO = CreateObject("Scripting.FileSystemObject")
strCurrentDir = objFSO.GetParentFolderName(WScript.ScriptFullName)

' 构建PowerShell脚本的完整路径
strCommand = "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strCurrentDir & "\LoginScript.ps1"""

' 使用wscript执行命令，隐藏窗口
objShell.Run strCommand, 0, False
