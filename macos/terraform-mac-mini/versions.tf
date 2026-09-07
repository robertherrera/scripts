terraform {
  # terraform_data (used in place of null_resource) requires 1.4+
  required_version = ">= 1.4.0"

  # No providers are needed: terraform_data is built in, which means
  # `terraform init` works on a freshly imaged Mac with no registry access.
}
