# iac-terraform-hands-on
Study IaC with terraform and codebase of all terraform practice


# Input Variables
In order, the priority of override variable in terraform
- Variable Default
- Environment Variable: `export TF_VAR_<name-variable>="<value>"`
- terraform.tfvars file 
```
<name-variable>=<value>
```
- terraform.tfvars.json
```
{
    <name-variable>:<value>
}
```
- *.auto.tfvars or *.auto.tfvars.json
- command line: -var and -var-file 
```
terraform plan -var <name-variable>="<value>" -var <name-variable-1>="<value-1>"
```