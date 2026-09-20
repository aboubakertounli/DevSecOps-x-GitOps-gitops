#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$base = "http://127.0.0.1:8080"
Write-Host "Hitting $base until Ctrl+C so Prometheus has more than a scrape of idle traffic."
$i = 0
while ($true) {
  $i++
  try {
    Invoke-RestMethod -Uri "$base/items" -Method POST -ContentType "application/json" -Body (@{ name = "n$i" } | ConvertTo-Json) | Out-Null
    if ($i % 7 -eq 0) {
      try { Invoke-RestMethod -Uri "$base/items/missing" -Method GET | Out-Null } catch { }
    }
    Invoke-RestMethod -Uri "$base/healthz" | Out-Null
  } catch {
    Write-Host $_
  }
  Start-Sleep -Milliseconds 300
}
