#!/bin/bash

##############################################
# QR Forge - Health Check Script
# Monitors application health and status
##############################################

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

# Get instance IP from Terraform
cd terraform
INSTANCE_IP=$(terraform output -raw instance_public_ip 2>/dev/null)
cd ..

if [ -z "$INSTANCE_IP" ]; then
    echo -e "${RED}Error: Could not get instance IP from Terraform${NC}"
    exit 1
fi

APP_URL="http://$INSTANCE_IP"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}QR Forge Health Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check 1: Ping the server
echo -e "${YELLOW}1. Checking server connectivity...${NC}"
if ping -c 1 -W 2 $INSTANCE_IP &> /dev/null; then
    print_status 0 "Server is reachable"
else
    print_status 1 "Server is not reachable"
    exit 1
fi

# Check 2: Check SSH access
echo ""
echo -e "${YELLOW}2. Checking SSH access...${NC}"
if ssh -i terraform/qr-forge.pem -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "exit" &> /dev/null; then
    print_status 0 "SSH access is working"
else
    print_status 1 "SSH access failed"
fi

# Check 3: Check if Docker is running
echo ""
echo -e "${YELLOW}3. Checking Docker status...${NC}"
DOCKER_STATUS=$(ssh -i terraform/qr-forge.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "sudo systemctl is-active docker" 2>/dev/null || echo "failed")
if [ "$DOCKER_STATUS" = "active" ]; then
    print_status 0 "Docker is running"
else
    print_status 1 "Docker is not running"
fi

# Check 4: Check if containers are running
echo ""
echo -e "${YELLOW}4. Checking Docker containers...${NC}"
CONTAINER_COUNT=$(ssh -i terraform/qr-forge.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "docker ps -q | wc -l" 2>/dev/null || echo "0")
if [ "$CONTAINER_COUNT" -gt 0 ]; then
    print_status 0 "Docker containers are running ($CONTAINER_COUNT container(s))"
    
    # Show container details
    echo ""
    echo -e "${BLUE}Running containers:${NC}"
    ssh -i terraform/qr-forge.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
else
    print_status 1 "No Docker containers running"
fi

# Check 5: HTTP endpoint check
echo ""
echo -e "${YELLOW}5. Checking application HTTP endpoint...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $APP_URL 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    print_status 0 "Application is responding (HTTP $HTTP_CODE)"
else
    print_status 1 "Application is not responding (HTTP $HTTP_CODE)"
fi

# Check 6: Health endpoint
echo ""
echo -e "${YELLOW}6. Checking health endpoint...${NC}"
HEALTH_STATUS=$(curl -s $APP_URL/health 2>/dev/null || echo "failed")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    print_status 0 "Health check passed"
else
    print_status 1 "Health check failed"
fi

# Check 7: Disk space
echo ""
echo -e "${YELLOW}7. Checking disk space...${NC}"
DISK_USAGE=$(ssh -i terraform/qr-forge.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "df -h / | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null || echo "100")
if [ "$DISK_USAGE" -lt 80 ]; then
    print_status 0 "Disk usage is healthy (${DISK_USAGE}% used)"
else
    print_status 1 "Disk usage is high (${DISK_USAGE}% used)"
fi

# Check 8: Memory usage
echo ""
echo -e "${YELLOW}8. Checking memory usage...${NC}"
MEMORY_USAGE=$(ssh -i terraform/qr-forge.pem -o StrictHostKeyChecking=no ubuntu@$INSTANCE_IP "free | grep Mem | awk '{printf \"%.0f\", \$3/\$2 * 100}'" 2>/dev/null || echo "100")
if [ "$MEMORY_USAGE" -lt 80 ]; then
    print_status 0 "Memory usage is healthy (${MEMORY_USAGE}% used)"
else
    print_status 1 "Memory usage is high (${MEMORY_USAGE}% used)"
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Health Check Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Application URL: $APP_URL${NC}"
echo -e "${GREEN}Instance IP: $INSTANCE_IP${NC}"
echo ""
echo -e "${YELLOW}To view logs:${NC}"
echo "ssh -i terraform/qr-forge.pem ubuntu@$INSTANCE_IP 'docker logs qr-forge'"
echo ""
echo -e "${YELLOW}To restart application:${NC}"
echo "ssh -i terraform/qr-forge.pem ubuntu@$INSTANCE_IP 'cd /opt/qr-forge && docker-compose restart'"
echo ""
