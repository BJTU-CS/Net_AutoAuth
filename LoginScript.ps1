# 获取当前用户的文档路径
$logFile = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('MyDocuments'), 'Net_AutoAuth_logfile.log')

# 检查并创建文件夹（如果不存在）
$logDirectory = [System.IO.Path]::GetDirectoryName($logFile)
# 检查文件夹是否存在，若不存在则创建
if (-Not (Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory -Force
}

# 检查日志文件是否存在，若不存在则创建
if (-Not (Test-Path -Path $logFile)) {
    New-Item -Path $logFile -ItemType File -Force
}
# 写入日志的函数
function Write-Log {
    param (
        [string]$message
    )
    # 获取当前时间戳
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    # 构建日志消息
    $logMessage = "$timestamp - $message"
    # 写入日志文件，确保使用 UTF-8 编码
    Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
    # 也输出到控制台
    Write-Host $message
}

# 获取排除部分内网IPv4地址的函数
function Get-ValidIPv4Address {
    # 获取所有活动状态的网络接口的IPv4地址
    $ipAddresses = Get-NetIPAddress | Where-Object {
        $_.AddressFamily -eq "IPv4" -and 
        $_.PrefixOrigin -ne "WellKnown" -and
        $_.IPAddress -notmatch "^10\." -and
        $_.IPAddress -notmatch "^192\.168\." -and
        $_.IPAddress -notmatch "^172\.(1[6-9]|2[0-9]|3[0-1])\."
    }

    # 输出调试信息并记录日志
    if ($ipAddresses.Count -eq 0) {
        Write-Log "没有找到符合条件的IPv4地址。"
        return $null
    }

    Write-Log "获取的IPv4地址（排除部分内网地址）："
    $ipAddresses | ForEach-Object { Write-Log $_.IPAddress }

    # 假设我们只需要第一个符合条件的IP地址
    return $ipAddresses[0].IPAddress
}

# 检查互联网连接的函数
function Test-InternetConnection {
    $ping = New-Object System.Net.NetworkInformation.Ping
    $pingReply = $ping.Send("8.8.8.8", 2000)  # Timeout of 2 seconds
    if ($pingReply.Status -eq "Success") {
        return $true
    } else {
        return $false
    }

}

# 执行登录的函数，使用GET方法
function Invoke-Login {
    # 获取有效的IPv4地址
    $wlan_user_ip = Get-ValidIPv4Address

    if ($null -eq $wlan_user_ip) {
        Write-Log "无法获取有效的IPv4地址，登录终止。"
        return
    }

    # 从环境变量获取账号和密码
    $user_account = (Get-Item Env:BJTUEthernetAccount).value
    $user_password = (Get-Item Env:BJTUEthernetPassword).value

    if ([string]::IsNullOrWhiteSpace($user_account) -or [string]::IsNullOrWhiteSpace($user_password)) {
        Write-Log "环境变量 BJTUEthernetAccount 或 BJTUEthernetPassword 未设置，登录终止。"
        return
    }

    # 定义参数
    $callback = "dr1004"
    $login_method = "1"
    $wlan_user_mac = "000000000000"
    $jsVersion = "4.2.1"
    $terminal_type = "1"
    $lang = "zh-cn"
    $v = "6563"

    # 构建登录URL
    $loginUrl = "https://login.bjtu.edu.cn:802/eportal/portal/login?callback=$callback&login_method=$login_method&user_account=$user_account&user_password=$user_password&wlan_user_ip=$wlan_user_ip&wlan_user_ipv6=&wlan_user_mac=$wlan_user_mac&wlan_ac_ip=&wlan_ac_name=&jsVersion=$jsVersion&terminal_type=$terminal_type&lang=$lang&v=$v"

    Write-Log "发送登录请求至：$loginUrl"
    $response = Invoke-WebRequest -Uri $loginUrl -Method GET -UseBasicParsing
    Write-Log $response.Content
}

# 主逻辑
if (-Not (Test-InternetConnection)) {
    Write-Log "未检测到互联网连接，尝试登录..."
    Invoke-Login
} else {
    Write-Log "互联网连接正常，无需登录。"
}
