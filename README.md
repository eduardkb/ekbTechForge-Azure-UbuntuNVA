# acme-UbuntuNVA-Project

## Project details and design:

## Configure AZ with Service Principal

- Generate Certificate:
	- 1. Generate a private key and a public self-signed certificate (valid for 365 days) running: $> openssl req -x509 -newkey rsa:2048 -keyout privkey.pem -out pubcert.pem -days 365 -nodes
	- 2. Combine them into a single file for az login with: $> cat privkey.pem pubcert.pem > mycert.pem
	- 3. Secure your private key file permissions with: $> chmod 600 mycert.pem privkey.pem
- Upload public certificate pubcert.pem file to Azure App Registration Certificates
- Use certificate mycert.pem file to login:
```sh
az login --service-principal \
  --username "<CLIENT_ID>" \
  --certificate ~/.az/mycert.pem \
  --tenant "<TENANT_ID>"
```

## Deploying:

- on the project's root folder execute each command one-by-one after terraform init for each one:
```sh
terraform -chdir="acme-hub-rg" apply -auto-approve
terraform -chdir="acme-app-rg" apply -auto-approve
terraform -chdir="acme-data-rg" apply -auto-approve
```

## Design text

Azure network infrastructure:
- VNET: vnet-platform-hub
	- SUBNET: snet-shared-services (CIDR: 10.0.1.0/24)
		- subnet has NSG hubnva-subnet-nsg
			- Internet egress Rule: Allow Source Any, Destination service tag: internet
		- contains VM "hubnva-vm" with fixed private IP 10.0.1.10
			- NIC with ip_forwarding_enabled = true
		
- VNET: acmeapp-vnet
	- VNET is peered to vnet-platform-hub and both sides have "receive forwarding traffic" enabled
	- SUBNET: acmeapp-subnet (CIDR: 10.20.1.0/24)
		- subnet has NSG acmeapp-nsg with only default rules
		- contains VM "acmeapp-vm" with dynamic private IP 10.20.1.4
	- ROUTE TABLE: acmeapp-rt with rules:
		- toDataVnet : 10.30.1.0/24 to 10.0.1.10
		- toInternet: 0.0.0.0/0 to 10.0.1.10
	
- VNET: acmedata-vnet
	- VNET is peered to vnet-platform-hub and both sides have "receive forwarding traffic" enabled
	- SUBNET: acmedata-subnet (CIDR: 10.30.1.0/24)
		- subnet has NSG acmedata-nsg with only default rules
		- contains VM "acmedata-vm" with dynamic private IP 10.30.1.4
	- ROUTE TABLE: acmedata-rt with rules:
		- toAppVnet : 10.20.1.0/24 to 10.0.1.10
		- toInternet: 0.0.0.0/0 to 10.0.1.10
		
- PUBLIC LOAD BALANCER: hubnva-lb	
	- Frontend IP Configuration: Public IP "hubnva-pip" with IP 20.97.116.99
	- Backend Pools: hubnva-backend-pool containing vm hubnva-vm with IP 10.0.1.10
	- Health probes: none created
	- Load balancing rules: none created
	- Outbound rules: hubnva-outbound configured:
		- Frontend IP address: public PIP (hubnva-pip)
		- Protocol: All
		- Backend Pool: hubnva-backend-pool
