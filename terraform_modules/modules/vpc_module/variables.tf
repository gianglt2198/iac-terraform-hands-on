variable "cidr_block_default" {
  type        = string
  description = "Declare a new cidr block range for IP address"
  #   default     = "10.0.0.0/22"
}

variable "environment" {
  type        = string
  description = "Declare env for running platform"
  #   default     = "development"
}

