# Hub Ubuntu NVA

This root module creates a resource group, subnet-associated NSG, Standard Load Balancer, static public IP, NIC, and Ubuntu 24.04 LTS VM in the existing hub subscription. The public IP is associated with the Load Balancer, not the VM NIC. The NSG denies all inbound traffic, allows outbound traffic only to the `Internet` service tag, and denies all other outbound traffic. The NIC attaches to the existing hub subnet and has Azure IP forwarding enabled. Cloud-init can enable Linux IPv4 forwarding and install nftables source NAT for destinations outside `nat_excluded_cidrs`; the Load Balancer outbound rule provides public egress SNAT.

## Configure and deploy

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and set the existing subnet name, hub region, unused static private IP, and SSH public key.
2. Ensure the Terraform identity can read the existing VNet/subnet, create resources in the hub subscription, and access the configured remote-state storage account.
3. Run `terraform init`, `terraform fmt -check`, `terraform validate`, review `terraform plan`, then run `terraform apply`.

The VM has no public IP. The subnet NSG is intentionally restrictive: it blocks inbound spoke traffic and outbound traffic to private/VNet destinations. Consequently, this policy prevents the NVA from forwarding spoke traffic and may disrupt every other resource attached to this shared subnet. Use a dedicated NVA subnet or add narrowly scoped exceptions if NVA forwarding or other subnet workloads must continue. NSGs are stateful, so response traffic for connections initiated outbound is allowed.

Spoke route tables must use the NVA's static private IP as the next hop; the Load Balancer does not replace the NVA as a route next hop. No Azure route tables or route rules are created. Include all internal spoke and hub address ranges in `nat_excluded_cidrs` if forwarding is enabled.