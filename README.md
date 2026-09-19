# GitOps desired state

Source of truth for the demo API running on a local kind/k3s cluster. **Humans and CI edit YAML here. Nothing in this repo deploys by talking to the Kubernetes API.** Argo CD watches `apps/demo` and reconciles.

Upstream app / CI: [DevSecOps-x-GitOps](https://github.com/aboubakertounli/DevSecOps-x-GitOps)

## Layout

```
apps/demo/     Kustomize for the demo Deployment + Service
argocd/        Application CR to apply once Argo CD is installed
policies/      Kyverno ClusterPolicies (latest tag, resources, non-root)
```

CI in the app repo runs `kustomize edit set image` against `apps/demo` and commits the new tag. That commit is the only deploy trigger.

## Manual preview (before Argo CD)

```bash
kubectl apply -k apps/demo
```

Do this only to read the YAML. The intended path is Argo CD auto-sync.
