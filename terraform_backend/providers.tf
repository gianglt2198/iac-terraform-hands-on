terraform {
  # Configure Backend by S3 ======
  #   backend "s3" {
  #   }
  # Configure Backend by http ===== 
  # Includes Get State, Lock State, Unlock State
  #   backend "http" {
  #   }
  # Configure Backend by remote ======
  # Need credential for remote by terraform login
  #   backend "remote" {
  #   }
  required_version = "~> 1.10.0"
  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}
