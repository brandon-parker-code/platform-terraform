# AKS platform Terraform

Shared Azure platform for **all** apps on this cluster (not just email-consumer-service):

- Resource group, AKS, ACR, Key Vault, workload identities, GitHub OIDC for CI

These files were copied from `email-consumer-service-gitops/terraform`. Existing Azure resources were created from that copy. **Do not `terraform apply` from a fresh clone** until:

1. Remote state is configured (Azure Storage backend), and
2. Existing resources are **imported** (or the old Cloud Shell state is recovered).

A new apply without state will try to create a second AKS/ACR/Key Vault.

Apply and import details: [`terraform/README.md`](terraform/README.md).

GitOps for the cluster lives in [cluster-gitops](https://github.com/brandon-parker-code/cluster-gitops). App charts and HelmReleases stay in per-app gitops repos (for example [email-consumer-service-gitops](https://github.com/brandon-parker-code/email-consumer-service-gitops)).
