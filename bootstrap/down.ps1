#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$KindBin = Join-Path $env:LOCALAPPDATA "kind\kind.exe"
$kind = if (Get-Command kind -ErrorAction SilentlyContinue) { (Get-Command kind).Source } elseif (Test-Path $KindBin) { $KindBin } else { throw "kind is not installed." }
& $kind delete cluster --name gitops-lab
