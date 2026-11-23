# 启动 Sentinel Dashboard（端口 8858），jar 不存在时自动下载
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSCommandPath
$jar = Join-Path $root "dashboard\sentinel-dashboard-1.8.8.jar"
$jarUrl = "https://github.com/alibaba/Sentinel/releases/download/1.8.8/sentinel-dashboard-1.8.8.jar"

if (-not (Test-Path $jar) -or (Get-Item $jar).Length -lt 20MB) {
    New-Item -ItemType Directory -Force -Path (Split-Path $jar) | Out-Null
    $mirrors = @(
        "https://ghfast.top/$jarUrl",
        "https://gh-proxy.com/$jarUrl",
        "$jarUrl"
    )
    foreach ($mirror in $mirrors) {
        Write-Host "下载 Dashboard: $mirror"
        curl.exe -L -C - --retry 3 --retry-delay 2 --max-time 600 -o $jar $mirror
        if ((Test-Path $jar) -and (Get-Item $jar).Length -gt 20MB) {
            break
        }
    }
}

if (-not (Test-Path $jar) -or (Get-Item $jar).Length -lt 20MB) {
    throw "sentinel-dashboard-1.8.8.jar 下载失败，请手动下载后放到 $jar"
}

Write-Host ""
Write-Host "控制台地址: http://127.0.0.1:8858"
Write-Host "默认账号: admin / sentinel"
Write-Host ""
java -jar $jar --server.port=8858
