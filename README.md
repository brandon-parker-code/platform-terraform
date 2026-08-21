# AKS platform Terraform

Shared Azure platform for **all** apps on this cluster (not just email-consumer-service):

- Resource group, AKS, ACR, Key Vault, workload identities, GitHub OIDC for CI
- AKS **Flux** extension (includes helm-controller) syncing [cluster-gitops](https://github.com/brandon-parker-code/cluster-gitops)
- **Container Insights** (pod stdout in a Log Analytics workspace, 30-day retention)

Do **not** run `flux bootstrap`. Terraform installs Flux. Helm is not a separate cluster install; Flux’s helm-controller applies HelmReleases.

These files were copied from `email-consumer-service-gitops/terraform`. After a greenfield apply, keep using this clone’s state (or a remote backend). A second apply from an empty state will try to create a second AKS/ACR/Key Vault.

Apply details: [`terraform/README.md`](terraform/README.md).

GitOps for the cluster lives in [cluster-gitops](https://github.com/brandon-parker-code/cluster-gitops). App charts and HelmReleases stay in per-app gitops repos (for example [email-consumer-service-gitops](https://github.com/brandon-parker-code/email-consumer-service-gitops)).
