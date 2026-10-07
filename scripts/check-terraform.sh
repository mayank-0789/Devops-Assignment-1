#!/usr/bin/env bash
source scripts/evidence.sh
terraform_check() {
 local folder="$1"
 cd "$ROOT/$folder"
 terraform version
 terraform fmt -check -recursive
 terraform init -backend=false -input=false -no-color
 terraform validate -no-color
 echo 'Scope: formatting, provider/module initialization, configuration validation. No AWS resources created; no apply/destroy performed.'
}
evidence session-18-terraform terraform_check session-18-terraform/terraform-s3-demo
evidence session-19-terraform-project terraform_check session-19-terraform-project
# Capstone infrastructure is separately validated as part of this suite.
evidence capstone-terraform terraform_check final-devops-project/terraform
