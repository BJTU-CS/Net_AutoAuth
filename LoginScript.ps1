# 检查互联网连接的函数
function Test-InternetConnection {
    $pingResult = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
    return $pingResult
}

# 执行登录的函数，使用GET方法
function Perform-Login {
    # 定义参数
    $callback = "dr1004"
    $login_method = "1"
    $user_account = "学号"
    $user_password = "密码"
    $wlan_user_ip = "填写固定IP"
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
    Perform-Login
} else {
    Write-Host "互联网连接正常，无需登录。"
}
