#!/bin/bash

##############################################
# QR Forge - Rollback Script
# Restores application from S3 backup
##############################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Get Terraform outputs
cd terraform
INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null)
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null)
cd ..

if [ -z "$INSTANCE_IP" ] || [ -z "$S3_BUCKET" ]; then
    print_error "Could not get instance IP or S3 bucket from Terraform"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}QR Forge Rollback Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# List available backups
print_info "Available backups in S3:"
echo ""
aws s3 ls s3://$S3_BUCKET/backups/ | nl
echo ""

# Ask user to select backup
read -p "Enter the number of the backup to restore (or 'q' to quit): " BACKUP_NUMBER

if [ "$BACKUP_NUMBER" = "q" ]; then
    print_info "Rollback cancelled"
    exit 0
fi

# Get the selected backup filename
BACKUP_FILE=$(aws s3 ls s3://$S3_BUCKET/backups/ | sed -n "${BACKUP_NUMBER}p" | awk '{print $4}')

if [ -z "$BACKUP_FILE" ]; then
    print_error "Invalid backup selection"
    exit 1
fi

echo ""
print_info "Selected backup: $BACKUP_FILE"
echo ""

# Confirm rollback
read -p "Are you sure you want to rollback to this backup? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_info "Rollback cancelled"
    exit 0
fi

LOCAL_BACKUP="/tmp/$BACKUP_FILE"

echo ""
print_info "Starting rollback process..."

# Step 1: Download backup from S3
print_info "Downloading backup from S3..."
aws s3 cp s3://$S3_BUCKET/backups/$BACKUP_FILE $LOCAL_BACKUP
print_success "Backup downloaded"

# Step 2: Upload to server
print_info "Uploading backup to server..."
scp -i terraform/qr-forge.pem -o StrictHostKeyChecking=no \
  $LOCAL_BACKUP \
  ubuntu@$INSTANCE_IP:/tmp/

print_success "Backup uploaded to server"

# Step 3: Stop containers and restore
print_info "Stopping containers and restoring backup..."
ssh -i terraform/qr-forge.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP << EOF
  # Stop containers
  cd /opt/qr-forge
  docker-compose down || true
  
  # Backup current state (just in case)
  sudo mv /opt/qr-forge /opt/qr-forge.old.\$(date +%s) || true
  
  # Extract backup
  sudo mkdir -p /opt/qr-forge
  cd /opt
  sudo tar -xzf /tmp/$BACKUP_FILE
  
  # Fix permissions
  sudo chown -R ubuntu:ubuntu /opt/qr-forge
  
  # Start containers
  cd /opt/qr-forge
  docker-compose up -d
  
  # Cleanup
  rm -f /tmp/$BACKUP_FILE
EOF

print_success "Application restored from backup"

# Step 4: Verify application
print_info "Verifying application..."
sleep 10

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$INSTANCE_IP 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    print_success "Application is running (HTTP $HTTP_CODE)"
else
    print_error "Application may not be running correctly (HTTP $HTTP_CODE)"
fi

# Cleanup local backup
rm -f $LOCAL_BACKUP

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Rollback completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Application URL: http://$INSTANCE_IP${NC}"
echo ""
echo -e "${YELLOW}Run health check: ./scripts/health-check.sh${NC}"
echo ""
