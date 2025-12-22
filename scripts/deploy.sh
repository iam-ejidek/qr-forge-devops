#!/bin/bash

##############################################
# QR Forge - Master Deployment Script
# With step control for resuming deployments
##############################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Parse command line arguments
START_STEP=1
END_STEP=4

while [[ $# -gt 0 ]]; do
    case $1 in
        --start)
            START_STEP="$2"
            shift 2
            ;;
        --end)
            END_STEP="$2"
            shift 2
            ;;
        --step)
            START_STEP="$2"
            END_STEP="$2"
            shift 2
            ;;
        --help)
            echo "Usage: ./deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --start N     Start from step N (1-4)"
            echo "  --end N       End at step N (1-4)"
            echo "  --step N      Run only step N"
            echo "  --help        Show this help message"
            echo ""
            echo "Steps:"
            echo "  1. Deploy Infrastructure (Terraform)"
            echo "  2. Configure Server (Install Docker)"
            echo "  3. Deploy Application"
            echo "  4. Health Check"
            echo ""
            echo "Examples:"
            echo "  ./deploy.sh                    # Run all steps"
            echo "  ./deploy.sh --start 2          # Start from step 2"
            echo "  ./deploy.sh --step 3           # Run only step 3"
            echo "  ./deploy.sh --start 2 --end 3  # Run steps 2 and 3"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check Terraform (only if running step 1)
    if [ $START_STEP -le 1 ] && [ $END_STEP -ge 1 ]; then
        if command -v terraform &> /dev/null; then
            print_success "Terraform is installed: $(terraform version | head -n1)"
        else
            print_error "Terraform is not installed. Please install it first."
            exit 1
        fi
    fi
    
    # Check Ansible (only if running steps 2 or 3)
    if [ $START_STEP -le 3 ] && [ $END_STEP -ge 2 ]; then
        if command -v ansible &> /dev/null; then
            print_success "Ansible is installed: $(ansible --version | head -n1)"
        else
            print_error "Ansible is not installed. Please install it first."
            exit 1
        fi
    fi
    
    # Check AWS credentials (only if running step 1)
    if [ $START_STEP -le 1 ] && [ $END_STEP -ge 1 ]; then
        if aws sts get-caller-identity &> /dev/null; then
            print_success "AWS credentials are configured"
        else
            print_error "AWS credentials not configured. Run 'aws configure'"
            exit 1
        fi
    fi
    
    # Check if app directory exists (only if running step 3)
    if [ $START_STEP -le 3 ] && [ $END_STEP -ge 3 ]; then
        if [ -d "app" ]; then
            print_success "QR Forge app directory found"
        else
            print_error "App directory not found. Please clone QR Forge into ./app/"
            print_info "Run: git clone https://github.com/abdulazeez9/qr-forge.git app"
            exit 1
        fi
    fi
    
    # Check if infrastructure exists (if starting from step 2+)
    if [ $START_STEP -ge 2 ]; then
        if [ -f "terraform/terraform.tfstate" ]; then
            print_success "Existing infrastructure found"
        else
            print_error "No infrastructure found. Please run step 1 first."
            print_info "Run: ./deploy.sh --step 1"
            exit 1
        fi
        
        # Check if inventory exists
        if [ -f "ansible/inventory/hosts.ini" ]; then
            print_success "Ansible inventory found"
        else
            print_error "Ansible inventory not found. Please run step 1 first."
            exit 1
        fi
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
        cd ..
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
        cd ..
        exit 1
    fi
    
    print_info "Testing Ansible connectivity..."
    if ansible qr_forge_servers -m ping -i inventory/hosts.ini; then
        print_success "Ansible connectivity verified"
    else
        print_error "Cannot connect to server. Check if instance is ready."
        print_info "You can retry this step later with: ./deploy.sh --step 2"
        cd ..
        exit 1
    fi
    
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
    print_header "Deployment Summary"
    
    cd terraform
    
    INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "N/A")
    APP_URL="http://$INSTANCE_IP"
    SSH_COMMAND=$(terraform output -raw ssh_command 2>/dev/null || echo "N/A")
    
    cd ..
    
    echo ""
    if [ "$INSTANCE_IP" != "N/A" ]; then
        echo -e "${GREEN}QR Forge Deployment Status${NC}"
        echo ""
        echo -e "${BLUE}Application URL:${NC} $APP_URL"
        echo -e "${BLUE}SSH Access:${NC} $SSH_COMMAND"
        echo ""
        echo -e "${YELLOW}Useful Commands:${NC}"
        echo "  Health Check:  ./scripts/health-check.sh"
        echo "  View Logs:     ssh -i terraform/qr-forge.pem ubuntu@$INSTANCE_IP 'docker logs qr-forge'"
        echo "  Restart App:   ./deploy.sh --step 3"
        echo "  Backup:        ./scripts/backup.sh"
        echo ""
    fi
    echo -e "${YELLOW}Steps Executed:${NC}"
    [ $START_STEP -le 1 ] && [ $END_STEP -ge 1 ] && echo "  ✓ Step 1: Infrastructure deployment"
    [ $START_STEP -le 2 ] && [ $END_STEP -ge 2 ] && echo "  ✓ Step 2: Server configuration"
    [ $START_STEP -le 3 ] && [ $END_STEP -ge 3 ] && echo "  ✓ Step 3: Application deployment"
    [ $START_STEP -le 4 ] && [ $END_STEP -ge 4 ] && echo "  ✓ Step 4: Health check"
    echo ""
}

# Main execution
main() {
    clear
    print_header "QR Forge DevOps Deployment Pipeline"
    
    if [ $START_STEP -ne 1 ] || [ $END_STEP -ne 4 ]; then
        print_info "Running custom step range: $START_STEP to $END_STEP"
    fi
    
    echo ""
    
    check_prerequisites
    echo ""
    
    # Step 1: Infrastructure
    if [ $START_STEP -le 1 ] && [ $END_STEP -ge 1 ]; then
        deploy_infrastructure
        echo ""
    else
        print_info "Skipping Step 1: Infrastructure deployment"
        echo ""
    fi
    
    # Step 2: Configuration
    if [ $START_STEP -le 2 ] && [ $END_STEP -ge 2 ]; then
        configure_server
        echo ""
    else
        print_info "Skipping Step 2: Server configuration"
        echo ""
    fi
    
    # Step 3: Application
    if [ $START_STEP -le 3 ] && [ $END_STEP -ge 3 ]; then
        deploy_application
        echo ""
    else
        print_info "Skipping Step 3: Application deployment"
        echo ""
    fi
    
    # Step 4: Health Check
    if [ $START_STEP -le 4 ] && [ $END_STEP -ge 4 ]; then
        run_health_check
        echo ""
    else
        print_info "Skipping Step 4: Health check"
        echo ""
    fi
    
    display_summary
}

# Run main function
main
