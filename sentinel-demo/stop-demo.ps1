# 停止演示用的 Sentinel Dashboard (8858) 与 demo 应用 (8082)
foreach ($port in @(8858, 8082)) {
    $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if (-not $conns) {
        Write-Host "端口 $port 未在监听"
        continue
    }
    foreach ($conn in $conns) {
        try {
            Stop-Process -Id $conn.OwningProcess -Force -ErrorAction Stop
            Write-Host "已停止端口 $port 上的进程 $($conn.OwningProcess)"
        } catch {
            Write-Host "停止端口 $port 上的进程 $($conn.OwningProcess) 失败: $($_.Exception.Message)"
        }
    }
}
