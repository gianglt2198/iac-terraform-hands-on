variable "contract_name" {
  type        = string
  description = "contract name of information"
  sensitive   = true
  default     = "Tome"
}

variable "contract_phone" {
  type        = string
  description = "contract phone of information"
  sensitive   = true
  default     = "0123456789"
}
