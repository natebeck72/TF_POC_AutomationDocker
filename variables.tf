variable "location" {
    type = string
    description = "Location where the resource will be created ie. run az account list-locations -o table and it is the name field"
}

variable "customername" {
    type = string
    description = "Customer's name no spaces or special characters"
}

variable "admin_username" {
    type = string
    description = "username pushed into the NGFW and Panorama"
}

variable "admin_password" {
    type = string
    description = "password pushed into the NGFW and Panorama for the username provided"
}

variable "firewall_version" {
    type = string
    description = "Version of NGFW to deploy"
    default = "latest"
}

variable "panorama_version" {
    type = string
    description = "Version of panorama to deploy"
    default = "10.1.6"
}

variable "SE_Email" {
    type = string
    description = "The PA SE Email address, used in corp sub's to identify the owner of RG's and machines"
}

variable "user_identifier" {
    type = string
    description = "value used to identify the user deploying, usually the beginning of your email address before the @xxx.com"
}

variable "cert_passphrase" {
    type = string
    description = "passphrase used to allow access to the pkcs12 file"
    default = "passphrase"
}

variable "cert_url" {
    type = string
    description = "Url to the cert pkcs12 file for loading into the panorama"
    default = "url"
}

variable "timezone" {
    type = string
    description = "Timezone nomenclature for PaloAlto Panorama - US/Pacific - US-Mountain US/Central - US/Eastern"
    default = "US/Pacific"
}

variable "panorama_sn" {
    type = string
    description = "Panorama serial number, this is used to license the panorama as part of the best practice job"
}