# Backend Configuration 

In general, we have multiple ways to store state file by defining backend state.
By default, the backend is `locals` and the path is `./terraform.tfstate`
Based on code, we can recognize that common definition is
```
backend "<type>" {}
```
For example
```
backend "s3" {}
```
We should define configuration in outside Terraform to enhance security of Terraform infrastructure.
To run configuration from `state_configurations`, we only need to add flag `-backend-config=<path-to-state-configuration>` 
For example 
```
terraform init -backend-config=state_configurations/s3.hcl -migrate-state
```
