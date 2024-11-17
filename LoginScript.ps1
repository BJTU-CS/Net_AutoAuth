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

    # 输出调试信息
    if ($ipAddresses.Count -eq 0) {
        Write-Host "没有找到符合条件的IPv4地址。"
        return $null
    }

    Write-Host "获取的IPv4地址（排除部分内网地址）："
    $ipAddresses | ForEach-Object { Write-Host $_.IPAddress }

    # 假设我们只需要第一个符合条件的IP地址
    return $ipAddresses[0].IPAddress
}

# 检查互联网连接的函数
function Test-InternetConnection {
    $pingResult = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
    return $pingResult
}

# 执行登录的函数，使用GET方法
function Invoke-Login {
    # 获取有效的IPv4地址
    $wlan_user_ip = Get-ValidIPv4Address

    if ($null -eq $wlan_user_ip) {
        Write-Host "无法获取有效的IPv4地址，登录终止。"
        return
    }

    # 从环境变量获取账号和密码
    $user_account = (Get-Item Env:BJTUEthernetAccount).value
    $user_password = (Get-Item Env:BJTUEthernetPassword).value

    if ([string]::IsNullOrWhiteSpace($user_account) -or [string]::IsNullOrWhiteSpace($user_password)) {
        Write-Host "环境变量 BJTUEthernetAccount 或 BJTUEthernetPassword 未设置，登录终止。"
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

    Invoke-WebRequest -Uri $loginUrl -Method GET -UseBasicParsing
}

# 主逻辑
if (-Not (Test-InternetConnection)) {
    Write-Host "未检测到互联网连接，尝试登录..."
    Invoke-Login
} else {
    Write-Host "互联网连接正常，无需登录。"
}
