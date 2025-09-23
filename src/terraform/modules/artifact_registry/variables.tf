variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "repository_id" {
  description = "The Artifact Registry repository ID"
  type        = string
}

variable "location" {
  description = "The location of the repository"
  type        = string
}

variable "description" {
  description = "The user-provided description of the repository"
  type        = string
  default     = null
}

variable "format" {
  description = "The format of packages that are stored in the repository"
  type        = string
  default     = "DOCKER"

  validation {
    condition     = contains(["DOCKER", "MAVEN", "NPM", "PYTHON", "APT", "YUM"], var.format)
    error_message = "Format must be one of: DOCKER, MAVEN, NPM, PYTHON, APT, YUM."
  }
}

variable "labels" {
  description = "Labels with user-defined metadata"
  type        = map(string)
  default     = {}
}