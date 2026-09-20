# GitOps desired state

This repo is the **only** place the cluster is allowed to take desired state from. CI in [DevSecOps-x-GitOps](https://github.com/aboubakertounli/DevSecOps-x-GitOps) never calls `kubectl`. It commits an image tag here. Argo CD notices the commit and reconciles.

```
apps/demo/            Deployment + Service (the API)
apps/observability/   Prometheus + Grafana + scrape config + dashboard
policies/             Kyverno ClusterPolicies (demo + observability namespaces)
argocd/               Application CRs applied once on an empty cluster
bootstrap/            kind cluster: Kyverno, Argo CD, then the Application CRs
```

## After a commit on the app repo (the real sequence)

1. GitHub Actions runs tests, Trivy (filesystem then image), builds, pushes `ghcr.io/aboubakertounli/devsecops-x-gitops:<sha>` .
2. If `GITOPS_TOKEN` is set, CI runs `kustomize edit set image` in `apps/demo` and **pushes a commit to this repo**. That commit is the deploy.
3. Argo CD (in the cluster) sees `apps/demo` changed, diffs live vs git, syncs.
4. The Kyverno webhook admits or rejects the new Pod (`:latest` forbidden, non-root, CPU/memory required).
5. Prometheus discovers the new Pod because of `prometheus.io/scrape` on the Deployment, scrapes `/metrics`.
6. Grafana reads Prometheus. Dashboard `Demo API` is provisioned from `apps/observability/configs/demo-api.json`.

## Bring the cluster up (Windows)

Docker Desktop must be running.

```powershell
cd "DevSecOps-x-GitOps-gitops"
powershell -File bootstrap\up.ps1
powershell -File bootstrap\ports.ps1
```

| UI | URL |
| --- | --- |
| Grafana (admin / admin) | http://127.0.0.1:3000 |
| Prometheus → Status → Targets | http://127.0.0.1:9090/targets |
| API metrics | http://127.0.0.1:8080/metrics |

`kubernetes-pods` on the Prometheus targets page must be **UP**. That is the scrape. Grafana is only a query UI on top of it.

```powershell
powershell -File bootstrap\traffic.ps1
```

Tear down: `powershell -File bootstrap\down.ps1`

## What you should not do

`kubectl apply -k apps/demo` deploys the same YAML, but it bypasses Argo CD. Use it only to *read* the rendered manifest (`kubectl kustomize apps/demo`).
