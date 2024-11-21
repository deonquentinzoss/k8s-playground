#!/bin/bash

# Variables
TERRAFORM_DIR="../terraform"  # Path to your Terraform configuration
INVENTORY_TEMPLATE="../ansible/inventory_template.yml"
ANSIBLE_INVENTORY="../ansible/inventory.yml"
SSH_DIR="$HOME/.ssh"

# Ensure the Terraform directory exists
if [[ ! -d "$TERRAFORM_DIR" ]]; then
  echo "Error: Terraform directory $TERRAFORM_DIR does not exist."
  exit 1
fi

# Ensure the inventory template exists
if [[ ! -f "$INVENTORY_TEMPLATE" ]]; then
  echo "Error: Inventory template $INVENTORY_TEMPLATE not found."
  exit 1
fi

# Change to Terraform directory
cd "$TERRAFORM_DIR" || exit

# Initialize Terraform
echo "Initializing Terraform in $TERRAFORM_DIR..."
terraform init -input=false
if [[ $? -ne 0 ]]; then
  echo "Error: Terraform initialization failed."
  exit 1
fi

# Apply Terraform configuration
echo "Applying Terraform configuration in $TERRAFORM_DIR..."
terraform apply -auto-approve
if [[ $? -ne 0 ]]; then
  echo "Error: Terraform apply failed."
  exit 1
fi

# Fetch the IPs from Terraform output
echo "Fetching Kubernetes node IPs from Terraform..."
IPS=$(terraform output -json k8s_ips | jq -r '.[]')

if [[ -z "$IPS" ]]; then
  echo "Error: No IPs found in Terraform output. Ensure your Terraform configuration is correct."
  exit 1
fi

echo "Found the following IPs:"
echo "$IPS"

# Change back to the original directory
cd - > /dev/null || exit

# Scan .ssh directory for private keys
echo "Scanning $SSH_DIR for private keys..."
PRIVATE_KEYS=$(find "$SSH_DIR" -type f -name "id_*" ! -name "*.pub")

if [[ -z "$PRIVATE_KEYS" ]]; then
  echo "Error: No private keys found in $SSH_DIR."
  exit 1
fi

# Function to display a menu and get the user's choice
select_option() {
  PS3="Please select a private key: "
  select opt in "$@"; do
    if [[ -n $opt ]]; then
      echo "$opt"
      return 0
    else
      echo "Invalid option. Try again."
    fi
  done
}

# Let the user choose a private key
echo "Available private keys:"
SELECTED_KEY=$(select_option $PRIVATE_KEYS)
echo "Selected private key: $SELECTED_KEY"

# Generate the Ansible inventory file using the template
echo "Generating Ansible inventory file: $ANSIBLE_INVENTORY from $INVENTORY_TEMPLATE"

cp "$INVENTORY_TEMPLATE" "$ANSIBLE_INVENTORY"

# Add dynamic IPs to the inventory
{
  echo "  hosts:"
  i=0
  for IP in $IPS; do
    echo "    k8s-node-$i:"
    echo "      ansible_host: $IP"
    i=$((i + 1))
  done
  echo "  vars:"
  echo "    ansible_user: ansible"
  echo "    ansible_ssh_private_key_file: $SELECTED_KEY"
} >> "$ANSIBLE_INVENTORY"

echo "Inventory file generated successfully:"
cat "$ANSIBLE_INVENTORY"

