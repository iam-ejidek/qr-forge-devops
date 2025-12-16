#!/bin/bash

##############################################
# QR Forge - Backup Script
# Backs up application data to S3
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

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="qr-forge-backup-${TIMESTAMP}.tar.gz"
LOCAL_BACKUP="/tmp/${BACKUP_FILE}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}QR Forge Backup Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_info "Starting backup process..."
echo ""

# Step 1: Create backup on remote server
print_info "Creating backup on server..."
ssh -i terraform/qr-forge.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP << 'EOF'
  # Create backup directory
  mkdir -p /tmp/qr-forge-backup
  
  # Backup Docker volumes
  cd /opt/qr-forge
  sudo tar -czf /tmp/qr-forge-backup.tar.gz \
    docker-compose.yml \
    app/ \
    2>/dev/null || true
  
  echo "Backup created on server"
EOF

print_success "Backup created on server"

# Step 2: Download backup to local machine
print_info "Downloading backup to local machine..."
scp -i terraform/qr-forge.pem -o StrictHostKeyChecking=no \
  ubuntu@$INSTANCE_IP:/tmp/qr-forge-backup.tar.gz \
  $LOCAL_BACKUP

print_success "Backup downloaded: $LOCAL_BACKUP"

# Step 3: Upload to S3
print_info "Uploading backup to S3..."
aws s3 cp $LOCAL_BACKUP s3://$S3_BUCKET/backups/$BACKUP_FILE

print_success "Backup uploaded to S3: s3://$S3_BUCKET/backups/$BACKUP_FILE"

# Step 4: Cleanup
print_info "Cleaning up temporary files..."
rm -f $LOCAL_BACKUP
ssh -i terraform/qr-forge.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP \
  "rm -f /tmp/qr-forge-backup.tar.gz"

print_success "Cleanup completed"

# Step 5: List recent backups
echo ""
print_info "Recent backups in S3:"
aws s3 ls s3://$S3_BUCKET/backups/ | tail -5

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Backup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Backup file: $BACKUP_FILE${NC}"
echo -e "${BLUE}S3 location: s3://$S3_BUCKET/backups/$BACKUP_FILE${NC}"
echo ""
