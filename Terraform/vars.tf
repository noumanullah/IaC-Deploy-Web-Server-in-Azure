variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
}

variable "location" {
  description = "The Azure Region in which all resources in this example should be created"
}

variable "admin_username" {
    type = string
    description = "Administrator user name for virtual machine"
}

variable "admin_password" {
    type = string
    description = "Password must meet Azure complexity requirements"
}

variable "vmimage" {
    type = string
	  default = "/subscriptions/7034ssf8-ssss-xxxx-xxxx-bf1e1a93ff47/resourceGroups/Nouman_Udacity_Project1/providers/Microsoft.Compute/images/linuxPackerImage"
}

variable "vmcount" {
	description = "Numnber of VMs (minimum 2 and no more than 5): "
	type = number
	validation {
		condition = can(regex("2|3|4|5", var.vmcount))
		error_message = "The condition did not meet."
	}
}
