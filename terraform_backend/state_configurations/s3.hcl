bucket = "my-terraform-state"
path   = "states/state"
region = "us-east-1"
# Locking state in dynamoDB
dynamodb_table = "terraform-locks"
encrypt        = true