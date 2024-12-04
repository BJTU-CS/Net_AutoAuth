function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Task {
    # 定义任务名称和脚本路径
    $taskName = "BJTUNetLogin"
    $sourceScriptPath = Join-Path $PSScriptRoot "LoginScript.ps1"  # 使用 $PSScriptRoot
    $destinationFolder = "$env:USERPROFILE\bjtu_scripts"
    $destinationScriptPath = Join-Path $destinationFolder "LoginScript.ps1"

    # 检查源脚本路径是否存在
    if (-Not (Test-Path $sourceScriptPath)) {
        Write-Host "错误：源脚本路径不存在：$sourceScriptPath" -ForegroundColor Red
        return
    }

    # 创建目标文件夹（如果不存在）
    if (-Not (Test-Path $destinationFolder)) {
        New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
    }

    # 复制脚本到目标位置
    try {
        Copy-Item -Path $sourceScriptPath -Destination $destinationScriptPath -Force
        Write-Host "脚本已成功复制到：$destinationScriptPath" -ForegroundColor Green
    } catch {
        Write-Host "错误：无法复制脚本到目标位置。错误信息：$($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # 提示用户输入环境变量值
    Write-Host "请输入您的账号（BJTUEthernetAccount）："
    $account = Read-Host
    Write-Host "请输入您的密码（BJTUEthernetPassword）："
    $password = Read-Host

    try {
        # 设置环境变量
        [Environment]::SetEnvironmentVariable("BJTUEthernetAccount", $account, "Machine")
        [Environment]::SetEnvironmentVariable("BJTUEthernetPassword", $password, "Machine")
        Write-Host "环境变量已成功设置。" -ForegroundColor Green
    } catch {
        Write-Host "错误：无法设置环境变量。错误信息：$($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # 创建计划任务的触发器（用户登录时触发）
    $trigger = New-ScheduledTaskTrigger -AtLogOn

    # 创建计划任务的操作
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$destinationScriptPath`""

    # 运行计划任务时不需要用户登录
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd

    # 使用指定的用户创建任务
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name # 获取用户名
    $password = Read-Host "输入当前计算机用户的密码，如果为空则直接回车"

    # 检查是否已经存在同名任务
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-Host "警告：任务 $taskName 已存在，正在覆盖..." -ForegroundColor Yellow
        try {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        } catch {
            Write-Host "错误：无法删除现有任务 $taskName。错误信息：$($_.Exception.Message)" -ForegroundColor Red
            return
        }
    }

    # 注册计划任务
    try {
        if ($password.Length -eq 0) {
            Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -User "$user" -Description "BJTU Net Auto Login" -Force
            Write-Host "任务 $taskName 已成功注册，并将在启动时运行。" -ForegroundColor Green
        } else {
            Register-ScheduledTask -TaskName $taskName -Trigger $trigger -Action $action -Settings $settings -User "$user" -Password $password -Description "BJTU Net Auto Login" -Force
            Write-Host "任务 $taskName 已成功注册，并将在启动时运行。" -ForegroundColor Green
        }
    } catch {
        Write-Host "错误：无法注册任务 $taskName。错误信息：$($_.Exception.Message)" -ForegroundColor Red
    }
}

function Uninstall-Task {
    $taskName = "BJTUNetLogin"
    $destinationFolder = "$env:USERPROFILE\bjtu_scripts"
    $destinationScriptPath = Join-Path $destinationFolder "LoginScript.ps1"

    # 检查是否已经存在同名任务
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        try {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Host "任务 $taskName 已成功卸载。" -ForegroundColor Green
        } catch {
            Write-Host "错误：无法卸载任务 $taskName。错误信息：$($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "任务 $taskName 不存在。" -ForegroundColor Yellow
    }

    # 检查并删除脚本文件
    if (Test-Path $destinationScriptPath) {
        try {
            Remove-Item -Path $destinationScriptPath -Force
            Write-Host "脚本文件 $destinationScriptPath 已成功删除。" -ForegroundColor Green
        } catch {
            Write-Host "错误：无法删除脚本文件 $destinationScriptPath。错误信息：$($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "脚本文件 $destinationScriptPath 不存在，无需删除。" -ForegroundColor Yellow
    }

    # 检查并删除空的目标文件夹
    if ((Test-Path $destinationFolder) -and ((Get-ChildItem -Path $destinationFolder | Measure-Object).Count -eq 0)) {
        try {
            Remove-Item -Path $destinationFolder -Force
            Write-Host "空文件夹 $destinationFolder 已成功删除。" -ForegroundColor Green
        } catch {
            Write-Host "错误：无法删除文件夹 $destinationFolder。错误信息：$($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "目标文件夹 $destinationFolder 非空或不存在，无需删除。" -ForegroundColor Yellow
    }

    # 判断并删除环境变量
    try {
        # 检查 BJTUEthernetAccount 是否存在
        if ($null -ne [Environment]::GetEnvironmentVariable("BJTUEthernetAccount", "Machine")) {
            [Environment]::SetEnvironmentVariable("BJTUEthernetAccount", $null, "Machine")
            Write-Host "环境变量 BJTUEthernetAccount 已成功删除。" -ForegroundColor Green
        } else {
            Write-Host "环境变量 BJTUEthernetAccount 不存在。" -ForegroundColor Yellow
        }

        # 检查 BJTUEthernetPassword 是否存在
        if ($null -ne [Environment]::GetEnvironmentVariable("BJTUEthernetPassword", "Machine")) {
            [Environment]::SetEnvironmentVariable("BJTUEthernetPassword", $null, "Machine")
            Write-Host "环境变量 BJTUEthernetPassword 已成功删除。" -ForegroundColor Green
        } else {
            Write-Host "环境变量 BJTUEthernetPassword 不存在。" -ForegroundColor Yellow
        }
        } catch {
            Write-Host "错误：无法删除环境变量。错误信息：$($_.Exception.Message)" -ForegroundColor Red
    }
}



# 如果没有管理员权限，则请求提升
if (-Not (Test-Admin)) {
    try {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    } catch {
        Write-Host "错误：无法提升到管理员权限。请手动以管理员身份运行此脚本。" -ForegroundColor Red
        exit 1
    }
}

# 菜单系统
while ($true) {
    Write-Host "选择一个选项：" -ForegroundColor Cyan
    Write-Host "1. 安装任务"
    Write-Host "2. 卸载任务"
    Write-Host "3. 退出"

    $choice = Read-Host "请输入您的选择（1/2/3）"

    switch ($choice) {
        "1" { Install-Task }
        "2" { Uninstall-Task }
        "3" { exit }
        default { Write-Host "无效的选择，请重试。" -ForegroundColor Red }
    }
}
