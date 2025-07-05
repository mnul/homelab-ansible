#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
# The target server name is passed as the first argument to the script
TARGET_SERVER="$1"
# GitHub SSH URLs for your other repos
PUBLIC_REPO_URL="git@github.com:your_user/homelab.git"
PRIVATE_REPO_URL="git@github.com:your_user/homelab-private.git"

# Check if target server name was provided
if [ -z "$TARGET_SERVER" ]; then
    echo "Error: No target server name provided."
    echo "Usage: ./run_provision.sh <server-name>"
    exit 1
fi

echo "-----> Setting up environment..."

# Navigate to the parent directory of the current repo checkout
cd ..

# Clone the public and private repos
echo "-----> Cloning dependent repositories..."
git clone "$PUBLIC_REPO_URL" homelab
git clone "$PRIVATE_REPO_URL" homelab-private

# Create the vault password file from the environment variable provided by Semaphore
echo "-----> Creating vault password file..."
if [ -z "$SEMAPHORE_VAULT_PASSWORD" ]; then
    echo "Error: SEMAPHORE_VAULT_PASSWORD environment variable not set."
    exit 1
fi
echo "$SEMAPHORE_VAULT_PASSWORD" > ./homelab-private/.vault_pass.txt

# Navigate back into the ansible repo to run the playbook
cd homelab-ansible

echo "-----> Running Ansible playbook for target: ${TARGET_SERVER}"

# Run the playbook, passing the target server as an extra variable
ansible-playbook playbooks/provision_server.yaml -e "target_server=${TARGET_SERVER}"

echo "-----> Playbook finished successfully."