#!/bin/bash

##############################################
# QR Forge - Master Deployment Script
# This script orchestrates the complete deployment
##############################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Terraform
    if command -v terraform &> /dev/null; then
        print_success "Terraform is installed: $(terraform version | head -n1)"
    else
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check Ansible
    if command -v ansible &> /dev/null; then
        print_success "Ansible is installed: $(ansible --version | head -n1)"
    else
        print_error "Ansible is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS credentials are configured"
    else
        print_error "AWS credentials not configured. Run 'aws configure'"
        exit 1
    fi
    
    # Check if app directory exists
    if [ -d "app" ]; then
        print_success "QR Forge app directory found"
    else
        print_error "App directory not found. Please clone QR Forge into ./app/"
        exit 1
    fi
}

deploy_infrastructure() {
    print_header "Step 1: Deploying Infrastructure with Terraform"
    
    cd terraform
    
    print_info "Initializing Terraform..."
    terraform init
    
    print_info "Validating Terraform configuration..."
    terraform validate
    
    print_info "Planning infrastructure changes..."
    terraform plan -out=tfplan
    
    echo ""
    read -p "Do you want to apply these changes? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        print_error "Deployment cancelled by user"
        exit 1
    fi
    
    print_info "Applying Terraform configuration..."
    terraform apply tfplan
    
    # Get outputs
    export INSTANCE_IP=$(terraform output -raw instance_public_ip)
    export INSTANCE_ID=$(terraform output -raw instance_id)
    
    print_success "Infrastructure deployed successfully"
    print_info "Instance IP: $INSTANCE_IP"
    print_info "Instance ID: $INSTANCE_ID"
    
    cd ..
    
    # Wait for instance to be fully ready
    print_info "Waiting 60 seconds for instance to initialize..."
    sleep 60
}

configure_server() {
    print_header "Step 2: Configuring Server with Ansible"
    
    cd ansible
    
    # Verify inventory file was created
    if [ ! -f "inventory/hosts.ini" ]; then
        print_error "Ansible inventory not found. Terraform may have failed."
        exit 1
    fi
    
    print_info "Testing Ansible connectivity..."
    ansible qr_forge_servers -m ping -i inventory/hosts.ini
    
    print_info "Installing Docker..."
    ansible-playbook -i inventory/hosts.ini playbooks/01-install-docker.yml
    
    print_success "Server configuration completed"
    
    cd ..
}

deploy_application() {
    print_header "Step 3: Deploying QR Forge Application"
    
    cd ansible
    
    print_info "Deploying QR Forge with Docker..."
    ansible-playbook -i inventory/hosts.ini playbooks/03-deploy-app.yml
    
    print_success "Application deployed successfully"
    
    cd ..
}

run_health_check() {
    print_header "Step 4: Running Health Check"
    
    if [ -f "scripts/health-check.sh" ]; then
        chmod +x scripts/health-check.sh
        ./scripts/health-check.sh
    else
        print_info "Health check script not found, skipping..."
    fi
}

display_summary() {
    print_header "Deployment Complete! 🎉"
    
    cd terraform
    
    INSTANCE_IP=$(terraform output -raw instance_public_ip)
    APP_URL="http://$INSTANCE_IP"
    SSH_COMMAND=$(terraform output -raw ssh_command)
    
    cd ..
    
    echo ""
    echo -e "${GREEN}QR Forge is now live!${NC}"
    echo ""
    echo -e "${BLUE}Application URL:${NC} $APP_URL"
    echo -e "${BLUE}SSH Access:${NC} $SSH_COMMAND"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Visit your application: $APP_URL"
    echo "2. (Optional) Configure a domain name in Route53"
    echo "3. (Optional) Set up SSL with Let's Encrypt"
    echo "4. Monitor with: ./scripts/health-check.sh"
    echo ""
    echo -e "${GREEN}Happy QR Code Generating! 🚀${NC}"
    echo ""
}

# Main execution
main() {
    clear
    print_header "QR Forge DevOps Deployment Pipeline"
    echo ""
    
    check_prerequisites
    echo ""
    
    deploy_infrastructure
    echo ""
    
    configure_server
    echo ""
    
    deploy_application
    echo ""
    
    run_health_check
    echo ""
    
    display_summary
}

# Run main function
main
