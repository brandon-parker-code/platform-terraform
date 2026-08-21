# Terraform — AKS, ACR, Key Vault, identities

Provisions the Azure platform. **Prod** owns shared ACR, Log Analytics, and the GitHub Actions identity. **Dev** is a second AKS + Key Vault + workload identity in `rg-ecs-dev` that attaches to those shared resources.

- Resource group `rg-ecs-<env>` (AKS, Key Vault, workload identity)
- Shared ACR in the prod RG (`AcrPull` on every cluster kubelet, `AcrPush` on the GHA identity)
- AKS with OIDC issuer, Workload Identity, and the Key Vault Secrets Store CSI addon
- Key Vault per environment with Azure RBAC (same secret names in each vault)
- Workload user-assigned identity federated to `system:serviceaccount:email-consumer-service:email-consumer-service` on **that** cluster
- One GitHub Actions identity federated to `main`, `environment:prod`, and `environment:dev`
- `Key Vault Secrets User` for the workload identity (that environment’s vault only)
- `Key Vault Administrator` for the identity running Terraform (plus optional extra admin)
- One Log Analytics workspace; each cluster has `oms_agent` plus its own `MSCI-*` DCR

This stack does **not** create Key Vault secret values or GitHub Actions workflows. It **does** install the AKS Flux extension (source, kustomize, **helm**, and notification controllers) and points it at `cluster-gitops` path `./clusters/<environment>`.

Do not also run `flux bootstrap`.

Set `github_flux_token` in `terraform.tfvars` / `terraform.tfvars.dev` (gitignored) to a GitHub PAT with Contents: Read on `cluster-gitops` and `email-consumer-service-gitops`.

**State:** prod and dev must be **different Terraform workspaces**. Applying `environment=dev` in the prod workspace is blocked, because it would replace prod. Cloud Shell local state is per workspace (`terraform.tfstate.d/`).

Default AKS node size is `Standard_D2s_v7`. Some `eastus` subscriptions reject `Standard_D2s_v3`. Dev example uses 1 node; prod example uses 2.

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

Keep `environment = "prod"`. Leave the workspace as `default` (or `prod`).

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

Record these outputs as GitHub Actions **variables** on **email-consumer-service**. **Prod and dev GitHub Environments use the same Azure values** (shared ACR and GHA identity):

| Output (use this name in GitHub) | GitHub |
| --- | --- |
| `AZURE_CLIENT_ID` | Environment variable `AZURE_CLIENT_ID` (both `prod` and `dev`) |
| `AZURE_TENANT_ID` | Environment variable `AZURE_TENANT_ID` |
| `AZURE_SUBSCRIPTION_ID` | Environment variable `AZURE_SUBSCRIPTION_ID` |
| `ACR_LOGIN_SERVER` | Environment variable `ACR_LOGIN_SERVER` |

`workload_identity_client_id` and `key_vault_name` are **per cluster**. Put those in that environment’s GitOps `values.yaml`, not in GitHub.

```bash
az aks get-credentials --resource-group rg-ecs-prod --name aks-ecs-prod
kubectl get nodes
```

### Dev environment

Apply **prod first** so the shared ACR/workspace/GHA identity exist, including the `environment:dev` federated credential.

Push `clusters/dev` in cluster-gitops and `apps/dev` in email-consumer-service-gitops **before** the Flux configuration can sync.

```bash
cd terraform
terraform workspace select default
terraform output acr_name
terraform output log_analytics_workspace_name
terraform output gha_identity_name

cp terraform.tfvars.dev.example terraform.tfvars.dev
# set subscription_id, github_flux_token, and shared_* from the outputs above

terraform workspace new dev    # first time only
terraform workspace select dev
terraform plan  -var-file=terraform.tfvars.dev
terraform apply -var-file=terraform.tfvars.dev
```

Then:

```bash
az aks get-credentials --resource-group rg-ecs-dev --name aks-ecs-dev --overwrite-existing
```

Fill `REPLACE_*` in `email-consumer-service-gitops/apps/dev/email-consumer-service/values.yaml` (workload identity, Key Vault, Kafka). Image repository stays the shared ACR. Create the four Key Vault secrets in the **dev** vault. Create GitHub Environment **dev** with the **same** Azure variables as prod, plus secret `GITOPS_TOKEN` if it is not already at repo level.

Switch back to prod:

```bash
terraform workspace select default
```

### Existing cluster: import the portal DCR

If Container Insights was already repaired in the portal (`MSCI-eastus-aks-ecs-prod`), import it before `terraform apply`. Otherwise apply tries to create a rule that already exists.

```bash
SUB=$(az account show --query id -o tsv)
RG=$(terraform output -raw resource_group_name)
AKS=$(terraform output -raw aks_name)

terraform import azurerm_monitor_data_collection_rule.container_insights \
  "/subscriptions/${SUB}/resourceGroups/${RG}/providers/Microsoft.Insights/dataCollectionRules/MSCI-eastus-aks-ecs-prod"

terraform import azurerm_monitor_data_collection_rule_association.container_insights \
  "/subscriptions/${SUB}/resourceGroups/${RG}/providers/Microsoft.ContainerService/managedClusters/${AKS}/providers/Microsoft.Insights/dataCollectionRuleAssociations/ContainerInsightsExtension"
```

## GitHub OIDC subjects

GitHub includes numeric owner and repository ids in the token `sub` claim. Federated credentials on the **shared** identity `id-ecs-prod-gha`:

- `repo:brandon-parker-code@79738728/email-consumer-service@1271894694:ref:refs/heads/main`
- `repo:brandon-parker-code@79738728/email-consumer-service@1271894694:environment:prod`
- `repo:brandon-parker-code@79738728/email-consumer-service@1271894694:environment:dev`

If login fails with `AADSTS700213`, the assertion `sub` in the error must match these strings exactly. Update `github_org_id` / `github_repo_id` if GitHub shows different ids.

`v*` tag workflows use the **prod** GitHub Environment. **Deploy** to `dev` uses GitHub Environment **dev** (same `AZURE_CLIENT_ID`).
