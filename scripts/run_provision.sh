#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
# The target server name is passed as the first argument to the script
TARGET_SERVER="$1"
# GitHub SSH URLs for your other repos. Replace 'your_user' with your GitHub username.
PUBLIC_DATA_REPO_URL="git@github.com:your_user/homelab.git"
PRIVATE_DATA_REPO_URL="git@github.com:your_user/homelab-private.git"

# --- Pre-flight Check ---
if [ -z "$TARGET_SERVER" ]; then
    echo "Error: No target server name provided."
    echo "Usage from Semaphore Arguments: <server-name>"
    exit 1
fi

echo "-----> Setting up environment..."

# The current directory is /opt/semaphore/tmp/project_.../repository_.../
# We need to go up one level to create our sibling directories.
cd ..

# --- Git Operations ---
echo "-----> Cloning dependent repositories..."
git clone "$PUBLIC_DATA_REPO_URL" homelab
git clone "$PRIVATE_DATA_REPO_URL" homelab-private

# --- Vault Setup ---
# Create the vault password file from the environment variable provided by Semaphore
echo "-----> Creating vault password file..."
if [ -z "$SEMAPHORE_VAULT_PASSWORD" ]; then
    echo "Error: SEMAPHORE_VAULT_PASSWORD environment variable not set in Semaphore Secrets."
    exit 1
fi
echo "$SEMAPHORE_VAULT_PASSWORD" > ./homelab-private/.vault_pass.txt

# --- Ansible Execution ---
# Navigate back into the ansible repo to run the playbook
# The directory name 'homelab-ansible' must match your repo name.
cd homelab-ansible

echo "-----> Running Ansible playbook for target: ${TARGET_SERVER}"
ansible-playbook playbooks/provision_server.yaml -e "target_server=${TARGET_SERVER}"

echo "-----> Playbook finished successfully."