$targets = Get-CimInstance Win32_Process | Where-Object {
    $_.CommandLine -and (
        $_.CommandLine -like "*org.apache.rocketmq.namesrv.NamesrvStartup*" -or
        $_.CommandLine -like "*org.apache.rocketmq.broker.BrokerStartup*"
    )
}

if (-not $targets) {
    Write-Host "没有发现运行中的 RocketMQ 进程"
    return
}

foreach ($p in $targets) {
    Write-Host "停止 PID $($p.ProcessId)"
    Stop-Process -Id $p.ProcessId -Force
}
Write-Host "RocketMQ 已停止"
