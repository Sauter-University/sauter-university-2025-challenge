variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "service_accounts" {
  description = "Map of service accounts to create with their configurations"
  type = map(object({
    account_id   = string
    display_name = string
    description  = string
    roles        = list(string)
  }))
  default = {}
}
