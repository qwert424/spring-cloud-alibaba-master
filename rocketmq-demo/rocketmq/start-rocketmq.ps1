param(
    [string]$RocketMqHome = "D:\devApplication\rocketmq\rocketmq-all-5.3.2-bin-release"
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
# 数据与日志统一放在 RocketMQ 安装目录的同级目录：D:\devApplication\rocketmq\
$instanceRoot = Split-Path -Parent $RocketMqHome
$logDir = Join-Path $instanceRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logRootArg = "-Drocketmq.log.root=" + ($logDir -replace '\\', '/')

if (-not $env:JAVA_HOME -or -not (Test-Path (Join-Path $env:JAVA_HOME "bin\java.exe"))) {
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    if (-not $javaCmd) { throw "没有找到 java，请先安装 JDK 17+ 并配置 JAVA_HOME" }
    $env:JAVA_HOME = Split-Path -Parent (Split-Path -Parent $javaCmd.Source)
}

$namesrvCmd = Join-Path $RocketMqHome "bin\mqnamesrv.cmd"
$brokerCmd = Join-Path $RocketMqHome "bin\mqbroker.cmd"
if (-not (Test-Path $namesrvCmd) -or -not (Test-Path $brokerCmd)) {
    throw "找不到 RocketMQ：$RocketMqHome，请修改脚本顶部的 `$RocketMqHome 或执行时传入 -RocketMqHome"
}

$env:ROCKETMQ_HOME = $RocketMqHome

# .cmd 走系统代码页，遇到中文路径会乱码，所以把配置复制到 RocketMQ 的纯英文目录
$brokerConf = Join-Path $RocketMqHome "conf\broker-demo.conf"
Copy-Item (Join-Path $here "broker.conf") $brokerConf -Force

# 用纯英文的启动脚本包一层，避免中文路径和引号在 cmd 里被转义坏
$namesrvLauncher = Join-Path $RocketMqHome "bin\start-namesrv-demo.cmd"
$brokerLauncher = Join-Path $RocketMqHome "bin\start-broker-demo.cmd"
[System.IO.File]::WriteAllText($namesrvLauncher, "@echo off`r`ncall `"%~dp0mqnamesrv.cmd`" -n 127.0.0.1:9876`r`n")
[System.IO.File]::WriteAllText($brokerLauncher, "@echo off`r`ncall `"%~dp0mqbroker.cmd`" -n 127.0.0.1:9876 -c `"%~dp0..\conf\broker-demo.conf`"`r`n")

function Test-Listening([int]$port) {
    return [bool](Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
}

function Wait-Port([int]$port, [int]$timeoutSeconds, [string]$name) {
    $deadline = (Get-Date).AddSeconds($timeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-Listening $port) { return }
        Start-Sleep -Milliseconds 500
    }
    throw "$name 在 $timeoutSeconds 秒内没有监听 $port 端口，请查看 $logDir 下的日志"
}

if (Test-Listening 9876) {
    Write-Host "[跳过] NameServer 已在 9876 端口运行"
} else {
    $env:JAVA_OPT_EXT = "$logRootArg -Xms512m -Xmx512m -Xmn256m -XX:MaxDirectMemorySize=256m"
    Start-Process -FilePath $env:ComSpec `
        -ArgumentList '/c', "`"$namesrvLauncher`"" `
        -RedirectStandardOutput (Join-Path $logDir "namesrv.out.log") `
        -RedirectStandardError (Join-Path $logDir "namesrv.err.log") `
        -WindowStyle Hidden | Out-Null
    Wait-Port 9876 60 "NameServer"
    Write-Host "[OK] NameServer 已启动: 127.0.0.1:9876"
}

if (Test-Listening 10911) {
    Write-Host "[跳过] Broker 已在 10911 端口运行"
} else {
    $env:JAVA_OPT_EXT = "$logRootArg -Xms1g -Xmx1g -Xmn512m -XX:MaxDirectMemorySize=512m"
    Start-Process -FilePath $env:ComSpec `
        -ArgumentList '/c', "`"$brokerLauncher`"" `
        -RedirectStandardOutput (Join-Path $logDir "broker.out.log") `
        -RedirectStandardError (Join-Path $logDir "broker.err.log") `
        -WindowStyle Hidden | Out-Null
    Wait-Port 10911 90 "Broker"
    Write-Host "[OK] Broker 已启动: 127.0.0.1:10911"
}

# 预建 Topic：否则消费者首次启动时还没有路由，要等约 20 秒才收到消息
$adminCmd = Join-Path $RocketMqHome "bin\mqadmin.cmd"
function Update-DemoTopic {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $adminCmd updateTopic -n 127.0.0.1:9876 -c DefaultCluster -t demo-topic 2>&1 | Out-Null
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }
}

$created = $false
for ($i = 0; $i -lt 15; $i++) {
    if ((Update-DemoTopic) -eq 0) { $created = $true; break }
    Start-Sleep -Seconds 1
}
if ($created) {
    Write-Host "[OK] Topic demo-topic 已就绪"
} else {
    Write-Warning "Topic demo-topic 创建失败，Broker 会自动创建（首次消费可能延迟约 20 秒）"
}

Write-Host ""
Write-Host "RocketMQ 已就绪。新的终端进入 rocketmq-demo 目录执行："
Write-Host "  mvn spring-boot:run"
