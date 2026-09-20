#Requires -Version 5.1
$ErrorActionPreference = "Stop"

Write-Host "Forwarding demo :8080, Prometheus :9090, Grafana :3000. Ctrl+C in each window to stop."

Start-Process kubectl -ArgumentList "-n","demo","port-forward","svc/demo","8080:8080" -WindowStyle Normal
Start-Process kubectl -ArgumentList "-n","observability","port-forward","svc/prometheus","9090:9090" -WindowStyle Normal
Start-Process kubectl -ArgumentList "-n","observability","port-forward","svc/grafana","3000:3000" -WindowStyle Normal
