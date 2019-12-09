// Terraform configuration
terraform {
  // Terraform version
  required_version = "~> 0.12.0"
  // Remote state configuration
  backend "s3" {

  }
}
