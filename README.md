# AKS platform Terraform

Shared Azure platform for **all** apps:

- **Shared (prod RG):** ACR, Log Analytics workspace, GitHub Actions identity
- **Per environment:** resource group, AKS, Key Vault, workload identity, Flux, Container Insights DCR

`prod` and `dev` are **separate AKS clusters**. Use Terraform workspaces so they do not share state. Dev reuses prod ACR, workspace, and GHA identity.

Do **not** run `flux bootstrap`. Terraform installs Flux. Helm is not a separate cluster install; Flux’s helm-controller applies HelmReleases.

These files were copied from `email-consumer-service-gitops/terraform`. After a greenfield apply, keep using this clone’s state (or a remote backend). A second apply from an empty state will try to create a second AKS/ACR/Key Vault.

Apply details: [`terraform/README.md`](terraform/README.md).

GitOps for the cluster lives in [cluster-gitops](https://github.com/brandon-parker-code/cluster-gitops). App charts and HelmReleases stay in per-app gitops repos (for example [email-consumer-service-gitops](https://github.com/brandon-parker-code/email-consumer-service-gitops)).
