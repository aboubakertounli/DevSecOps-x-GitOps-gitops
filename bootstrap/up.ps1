#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$KindVersion = "v0.27.0"
$KyvernoManifest = "https://github.com/kyverno/kyverno/releases/download/v1.13.4/install.yaml"
$ArgoManifest = "https://raw.githubusercontent.com/argoproj/argo-cd/v2.13.3/manifests/install.yaml"
$KindBin = Join-Path $env:LOCALAPPDATA "kind\kind.exe"

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true, Position = 0)] [string] $File,
    [Parameter(ValueFromRemainingArguments = $true)] $CmdArgs
  )
  & $File @CmdArgs
  if ($LASTEXITCODE -ne 0) {
    throw "$File failed with exit $LASTEXITCODE"
  }
}

function Assert-Docker {
  $deadline = (Get-Date).AddMinutes(5)
  do {
    docker info 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { return }
    Write-Host "Waiting for Docker Desktop..."
    Start-Sleep -Seconds 5
  } while ((Get-Date) -lt $deadline)
  throw "Docker is not running. Start Docker Desktop and re-run bootstrap/up.ps1."
}

function Install-Kind {
  if (Get-Command kind -ErrorAction SilentlyContinue) {
    return (Get-Command kind).Source
  }
  if (Test-Path $KindBin) { return $KindBin }
  $dir = Split-Path $KindBin
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Write-Host "Downloading kind $KindVersion"
  Invoke-WebRequest -Uri "https://github.com/kubernetes-sigs/kind/releases/download/$KindVersion/kind-windows-amd64" -OutFile $KindBin
  return $KindBin
}

Assert-Docker
$kind = Install-Kind

$clusters = @(& $kind get clusters 2>$null)
if ($clusters -notcontains "gitops-lab") {
  Write-Host "Creating kind cluster gitops-lab"
  Invoke-Checked $kind create cluster --config (Join-Path $PSScriptRoot "kind.yaml") --wait 180s
} else {
  Write-Host "kind cluster gitops-lab already exists"
  Invoke-Checked $kind export kubeconfig --name gitops-lab
}

Write-Host "Installing Kyverno"
Invoke-Checked kubectl apply --server-side --force-conflicts -f $KyvernoManifest
Invoke-Checked kubectl wait --namespace kyverno --for=condition=Available --timeout=180s deployment --all

Write-Host "Installing Argo CD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { throw "failed to create argocd namespace" }
Invoke-Checked kubectl apply -n argocd -f $ArgoManifest
Invoke-Checked kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s
Invoke-Checked kubectl wait --for=condition=Available deployment/argocd-repo-server -n argocd --timeout=180s
Start-Sleep -Seconds 10

Write-Host "Registering Argo CD Applications (demo, observability, policies)"
Invoke-Checked kubectl apply -f (Join-Path $Root "argocd")

Write-Host @"

Cluster is up. Argo CD will pull https://github.com/aboubakertounli/DevSecOps-x-GitOps-gitops.git
and reconcile. That is GitOps: kubectl is not deploying the app.

In another terminals, from this repo:

  kubectl -n argocd get applications
  kubectl -n demo get pods
  kubectl -n observability get pods

Then port-forward:

  powershell -File bootstrap\ports.ps1

Grafana  http://127.0.0.1:3000  (admin / admin)
Prometheus  http://127.0.0.1:9090  -> Status -> Targets (kubernetes-pods should be UP)
API  http://127.0.0.1:8080/metrics

Generate traffic:  powershell -File bootstrap\traffic.ps1
"@
