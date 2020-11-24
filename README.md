# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, we will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Deploy your infrasturcture as code in Azure

4. Destroy your infrastructure

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
Once you install all dependencies you need to verify if all latest versions are installed. 
Chceck the versions on Azure CLI using below commands:
* az --version
* terraform - version
* packer version

#### Steps to create Packer image
1. Open Azure CLI
2. Navigate to folder "Packer"
3. Edit variables.json and replaces values of
    1. client_id from Azure AD Application
    2. client_secret from newly created Azure AD Application "Certificates & Secrets"
    3. subscrtiption_id from Azure Subscription
    4. location from available list of Azure Locations
    5. vm_size from available list of Azure VM Sizes
4. Edit server.json and replaces values of
    1. Your resource group name in Azure Portal "managed_image_resource_group_name": "{Resource Group Name}",
    2. Replace the value to the name of image you want to create "managed_image_name": "{Name of image}",
5. Run Command: packer build -var-file variables.json server.json 

#### Steps to create IaC from Terraform template
1. Open Azure CLI
2. Navigate to folder "Terraform" in Azure CLI
3. Run command terraform init
4. Modify file "vars.tf" and replace vmimage default value to your newly created packerimage 
5. Run command terraform plan -out solution.plan and input desired values
    1. admin_password - Password of newly created VM - Password must meet Azure complexity requirements
    2. admin_username - Administrator user name for virtual machine
    3. location - The Azure Region in which all resources should be created
    4. prefix - The prefix which should be used for all resources including Resource Group
    5. vmcount - Numnber of VMs (minimum 2 and no more than 5)
6. Once plan created successfully, you can deploy it to Azure using command: terraform apply solution.plan

#### Customize the Terraform for your use
You can change vars.tf to customize the inputs if you like, you can add multiple variables, here are details of variables:
1. admin_password - Password of newly created VM - Password must meet Azure complexity requirements
2. admin_username - Administrator user name for virtual machine
3. location - The Azure Region in which all resources should be created
4. prefix - The prefix which should be used for all resources including Resource Group
5. vmcount - Numnber of VMs (minimum 2 and no more than 5)
    1. vmcount has a validation of minimum number of vm count accepted, you can change it to any other using Regex.
    ``` json
    validation {
		condition = can(regex("2|3|4|5", var.vmcount))
		error_message = "The condition did not meet."
	}

### Output
You will expect the following resources in newly created Resource Group from terraform template
* Availability Set
* Load Balancer
* Virtual Network
* Numbers of Network interfaces as input by number of VMs
* Network Security Group
* One Public IP assigened to Load Balancer
* Numbers of Virtual Machines as input by number of VMs
* Numbers of Disks attached with VMs by numbers of VMs
* Numbers of Managed Disks attached with VMs by numbers of VMs

