# Azure Ubuntu VM with remote Terraform state

Creates a resource group, a `10.20.0.0/16` virtual network, a `10.20.1.0/24` subnet, and one inexpensive `Standard_B1s` Ubuntu 24.04 LTS VM in **South Central US**. The VM has a private IP only: no inbound internet access is opened by default.

## Prerequisites

- Terraform 1.9 or later
- Azure CLI authenticated to the target tenant: `az login`
- An existing Azure subscription
- An existing, dedicated Azure Storage account and blob container for Terraform state

The state storage account must exist before `terraform init`. Keep it separate from the workload resource group, grant the deploying identity **Storage Blob Data Contributor** on the state container/account, and restrict its network access in production. Azure Blob native locking protects against concurrent state writes.

## Configure

1. Copy `backend.hcl.example` to `backend.hcl`; set the state resource group, storage-account name, container, and state key.
2. Copy `terraform.tfvars.example` to `terraform.tfvars`; set the workload `subscription_id`, hub subscription/resource group/VNet names, and an SSH **public** key.
3. From this directory, run:

   ```powershell
   terraform init -backend-config=backend.hcl
   terraform fmt -check
   terraform validate
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. To remove the workload when finished:

   ```powershell
   terraform destroy
   ```

## State backend notes

Terraform backend blocks are initialized before input variables, so backend values cannot come from `variables.tf`. This is why the state location lives in the ignored `backend.hcl` file. The provided configuration uses Microsoft Entra ID (`use_azuread_auth = true`) rather than storage access keys. Do not add secrets or credentials to `backend.hcl`, `terraform.tfvars`, source files, or version control.

For a quick state backend bootstrap, create a dedicated resource group, storage account, and private `tfstate` blob container through your approved Azure process. A storage account name must be globally unique.

## Network controls

The subnet NSG allows ICMP and TCP/80 only between addresses in the `VirtualNetwork` scope, then explicitly denies all other inbound and outbound traffic. The configuration creates peering in both directions between the workload VNet and the existing hub VNet. The Terraform identity must have permission to read and create peerings on both VNets, and the VNet address ranges must not overlap.
