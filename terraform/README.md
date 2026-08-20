# Terraform — AKS, ACR, Key Vault, identities

Provisions the **shared** Azure platform (AKS, ACR, Key Vault, identities). Multiple apps can use this cluster. Resource names still use the original `ecs-prod` prefix until they are renamed.

- Resource group `rg-ecs-prod`
- ACR (Standard, admin disabled, unique suffix)
- AKS with OIDC issuer, Workload Identity, and the Key Vault Secrets Store CSI addon
- Key Vault with Azure RBAC (no access policies), public access allowed
- Workload user-assigned identity federated to `system:serviceaccount:email-consumer-service:email-consumer-service`
- GitHub Actions user-assigned identity federated to `brandon-parker-code/email-consumer-service` (`main` and `environment:prod`)
- `AcrPull` for the AKS kubelet identity
- `AcrPush` for the GitHub Actions identity
- `Key Vault Secrets User` for the workload identity
- `Key Vault Administrator` for the identity running Terraform (plus optional extra admin)

This stack does **not** create Key Vault secret values, the Helm chart, Flux, or GitHub Actions workflows.

Default AKS node size is `Standard_D2s_v7`. Some `eastus` subscriptions reject `Standard_D2s_v3`.

## Prerequisites

- Terraform >= 1.6
- Azure CLI, logged in with rights to create RGs, AKS, ACR, Key Vault, managed identities, and role assignments
- The **subscription ID** (GUID), not a subscription display name and not your Entra user object ID

## Apply

Azure Cloud Shell (Bash) is enough; you do not need Terraform on your laptop.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Set `subscription_id` to the subscription that should own the resources:

```bash
az account list -o table
az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

If several subscriptions share a similar name, always use the GUID. Confirm later with:

```bash
az keyvault show --name kv-ecs-prod-XXXX --query id -o tsv
```

The GUID after `/subscriptions/` is the correct `subscription_id`. Your Entra user object ID (`az ad signed-in-user show --query id -o tsv`) is **not** a subscription ID.

Optionally set `key_vault_admin_object_id` for an extra admin. The applying identity is always granted Key Vault Administrator.

```bash
az login
terraform init
terraform plan
terraform apply
```

Keep the Cloud Shell tab active during AKS create (~10–15 minutes). If you see `Timeout waiting for token from portal` / Graph audience errors:

```bash
az logout
az login
az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
terraform apply
```

### Key Vault `GetCertificateContacts` / `context deadline exceeded`

The vault is often **already created** when this happens (RBAC vault + provider data-plane read). Do not delete it.

1. Confirm: `az keyvault list -g rg-ecs-prod -o table`
2. Wait a minute (or grant Key Vault Administrator if apply never got that far).
3. `terraform apply` again so Terraform refreshes the existing vault and continues with AKS/ACR/identities.

## After apply

Record these outputs as GitHub Actions variables/secrets on **email-consumer-service**:

| Output (use this name in GitHub) | GitHub |
| --- | --- |
| `AZURE_CLIENT_ID` | Environment **prod** secret `AZURE_CLIENT_ID` |
| `AZURE_TENANT_ID` | Environment **prod** secret `AZURE_TENANT_ID` |
| `AZURE_SUBSCRIPTION_ID` | Environment **prod** secret `AZURE_SUBSCRIPTION_ID` |
| `ACR_LOGIN_SERVER` | Repository or **prod** variable `ACR_LOGIN_SERVER` |

`workload_identity_client_id` is used later as the Helm value for `azure.workload.identity/client-id`.

```bash
az aks get-credentials --resource-group rg-ecs-prod --name aks-ecs-prod
kubectl get nodes
```

## GitHub OIDC subjects

GitHub includes numeric owner and repository ids in the token `sub` claim. Federated credentials are:

- `repo:brandon-parker-code@79738728/email-consumer-service@1271894694:ref:refs/heads/main`
- `repo:brandon-parker-code@79738728/email-consumer-service@1271894694:environment:prod`

If login fails with `AADSTS700213`, the assertion `sub` in the error must match these strings exactly. Update `github_org_id` / `github_repo_id` if GitHub shows different ids.

Tag-triggered workflows should use the `prod` GitHub Environment so the environment subject matches.
