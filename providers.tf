terraform {
    required_version = ">=1.0"

    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~>3.8"
        }
        aws = {
            source = "hashicorp/aws"
            version = "4.24.0"
        }
        local= {
            source = "hashicorp/local"
            version = "2.2.3"
        }
    }
}
provider "azurerm" {
    features {}
}

provider "aws" {}

provider "local" {}