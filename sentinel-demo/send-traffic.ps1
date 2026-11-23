# 给演示接口持续发请求，让 Dashboard 里有实时指标
param(
    [int]$Seconds = 60,
    [int]$Qps = 10
)

$targets = @(
    "http://127.0.0.1:8082/api/hello",
    "http://127.0.0.1:8082/api/slow",
    "http://127.0.0.1:8082/api/order/1",
    "http://127.0.0.1:8082/api/random"
)

$end = (Get-Date).AddSeconds($Seconds)
$count = 0
$delay = [Math]::Max(1, [int](1000 / $Qps))

while ((Get-Date) -lt $end) {
    $url = $targets[$count % $targets.Length]
    try {
        Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 | Out-Null
    } catch {
        # 限流/报错都是正常演示结果，忽略
    }
    $count++
    Start-Sleep -Milliseconds $delay
}

Write-Host "已发送 $count 次请求"
