.PHONY: all
all: install-dep terraform-cmd

# We use bashisms so this ensures stuff works as expected
SHELL := /bin/bash -l
TERRAFORM_VERSION := 0.12.16

# Download and install required binaries files
install-dep:
	curl -o terraform.zip \
	https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
	yes | unzip terraform.zip
	sudo chmod +x terraform && mv terraform /usr/bin

# Run terraform commands
terraform-cmd: terraform-fmt terraform-init terraform-plan terraform-apply

# Format the terraform code
terraform-fmt:
	cd terraform-templates && \
	terraform fmt

# Perform a terraform init parametrized per environment
terraform-init:
	cd terraform-templates && \
	terraform init -backend-config=environment/${TARGET_ENV}.conf -input=false
	terraform get -update terraform-templates

# Perform a validation of the terraform files parametrized per environment
terraform-validate:
	cd terraform-templates && \
	terraform validate -var-file=vars/${TARGET_ENV}.tfvars

# Produce the terraform plan parametrized per environment
terraform-plan:
	@cd terraform-templates && \
	terraform plan -var-file=vars/${TARGET_ENV}.tfvars -input=false -out=tfplan

# Apply the terraform plan parametrized per environment
terraform-apply:
	cd terraform-templates && \
	terraform apply -input=false -auto-approve tfplan

# Destroy the infrastructure provisioned on the environment specified by the TARGET_ENV parameter
terraform-destroy:
	@cd terraform-templates && \
	terraform destroy -input=false -auto-approve -refresh=false -var-file=vars/${TARGET_ENV}.tfvars

# Clear the terraform temporary files
clean:
	rm -rf terraform*
