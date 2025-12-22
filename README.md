# QR Forge - Complete DevOps Pipeline

![DevOps](https://img.shields.io/badge/DevOps-Ready-brightgreen)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange)
![Terraform](https://img.shields.io/badge/Terraform-IaC-purple)
![Ansible](https://img.shields.io/badge/Ansible-Configuration-red)
![Docker](https://img.shields.io/badge/Docker-Containerized-blue)

A production-ready DevOps pipeline for deploying **QR Forge**, a modern React-based QR Code Generator application on AWS infrastructure using Infrastructure as Code (IaC) best practices.

## 🏗️ Architecture Overview

```
┌─────────────┐
│   Internet  │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│  AWS Route53    │ (Optional DNS)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Elastic IP     │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────┐
│       EC2 Instance (t2.micro)    │
│  ┌────────────────────────────┐  │
│  │   Nginx (Reverse Proxy)    │  │
│  └──────────┬─────────────────┘  │
│             │                     │
│             ▼                     │
│  ┌────────────────────────────┐  │
│  │  Docker Container          │  │
│  │  ┌──────────────────────┐  │  │
│  │  │   QR Forge React App │  │  │
│  │  │   (Vite + TypeScript)│  │  │
│  │  └──────────────────────┘  │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
         │
         ▼
┌──────────────────┐
│   S3 Bucket      │
│   (Backups)      │
└──────────────────┘
```

## 🚀 Features

### Infrastructure (Terraform)
- ✅ **VPC & Networking**: Custom VPC with public subnet, Internet Gateway, and route tables
- ✅ **EC2 Instance**: Ubuntu 22.04 LTS with automated provisioning
- ✅ **Security Groups**: Proper firewall rules (HTTP, HTTPS, SSH)
- ✅ **Elastic IP**: Static IP for consistent access
- ✅ **S3 Bucket**: Automated backups with lifecycle policies
- ✅ **SSH Key Management**: Automated RSA key pair generation

### Configuration Management (Ansible)
- ✅ **Docker Installation**: Automated Docker Engine setup
- ✅ **Application Deployment**: Zero-downtime deployment process
- ✅ **Nginx Configuration**: Optimized reverse proxy with caching
- ✅ **Health Checks**: Automated monitoring and validation

### Containerization (Docker)
- ✅ **Multi-stage Build**: Optimized React production builds
- ✅ **Nginx Serving**: High-performance static file serving
- ✅ **PWA Support**: Service worker and manifest handling
- ✅ **Health Endpoints**: Container health monitoring

### Automation (Bash)
- ✅ **One-Command Deployment**: Complete infrastructure + app deployment
- ✅ **Health Monitoring**: Comprehensive health check script
- ✅ **Backup/Restore**: Automated S3 backup and rollback
- ✅ **Cleanup Scripts**: Resource cleanup and maintenance

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required Tools
- **Terraform** >= 1.0
  ```bash
  # macOS
  brew install terraform
  
  # Linux
  wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
  unzip terraform_1.6.0_linux_amd64.zip
  sudo mv terraform /usr/local/bin/
  ```

- **Ansible** >= 2.9
  ```bash
  # macOS
  brew install ansible
  
  # Linux
  sudo apt update
  sudo apt install ansible -y
  ```

- **AWS CLI** >= 2.0
  ```bash
  # macOS
  brew install awscli
  
  # Linux
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  ```

- **Git**
  ```bash
  # macOS
  brew install git
  
  # Linux
  sudo apt install git -y
  ```

### AWS Account Requirements
- Active AWS account
- IAM user with permissions for:
  - EC2 (create/manage instances)
  - VPC (networking)
  - S3 (buckets)
  - IAM (key pairs)

## 🎯 Quick Start

### Step 1: Clone and Setup

```bash
# Create project directory
mkdir qr-forge-devops
cd qr-forge-devops

# Clone QR Forge app into app folder
git clone https://github.com/abdulazeez9/qr-forge.git app

# Create project structure
mkdir -p terraform ansible/playbooks ansible/inventory docker scripts

# Initialize git for DevOps project
git init
```

### Step 2: Copy Configuration Files

Copy all the configuration files I've provided into their respective directories:

```
qr-forge-devops/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── s3.tf
│   ├── user-data.sh
│   └── inventory.tpl
├── ansible/
│   ├── playbooks/
│   │   ├── 01-install-docker.yml
│   │   └── 03-deploy-app.yml
│   └── ansible.cfg
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── nginx.conf
│   └── .dockerignore
├── scripts/
│   ├── deploy.sh
│   ├── health-check.sh
│   ├── backup.sh
│   └── rollback.sh
├── .gitignore
└── README.md
```

### Step 3: Configure AWS Credentials

```bash
# Option 1: Interactive configuration
aws configure

# Option 2: Export environment variables
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 4: Deploy Everything

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run complete deployment
./scripts/deploy.sh
```

This single command will:
1. ✅ Provision AWS infrastructure (VPC, EC2, S3)
2. ✅ Configure the server with Docker
3. ✅ Deploy the QR Forge application
4. ✅ Run health checks
5. ✅ Display your application URL

**Expected deployment time: 5-7 minutes**

## 📚 Detailed Usage

### Manual Step-by-Step Deployment

If you prefer to run steps manually:

#### 1. Provision Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

#### 2. Configure Server

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/01-install-docker.yml
```

#### 3. Deploy Application

```bash
ansible-playbook -i inventory/hosts.ini playbooks/03-deploy-app.yml
```

### Health Monitoring

```bash
# Run comprehensive health check
./scripts/health-check.sh

# Output includes:
# - Server connectivity
# - SSH access
# - Docker status
# - Container status
# - HTTP endpoint check
# - Disk and memory usage
```

### Backup & Restore

#### Create Backup

```bash
./scripts/backup.sh
```

This will:
- Create compressed backup of application
- Upload to S3 with timestamp
- Maintain 30-day retention policy

#### Restore from Backup

```bash
./scripts/rollback.sh

# Interactive menu:
# 1. Lists all available backups
# 2. Select backup to restore
# 3. Confirms and restores
```

## 🔧 Configuration

### Terraform Variables

Edit `terraform/variables.tf` to customize:

```hcl
variable "aws_region" {
  default = "us-east-1"  # Change region
}

variable "instance_type" {
  default = "t2.micro"   # Change instance size
}
```

### Docker Configuration

Modify `docker/nginx.conf` for:
- Custom caching policies
- Additional security headers
- URL rewrites
- CORS settings

## 📊 Monitoring & Maintenance

### View Application Logs

```bash
# SSH into server
ssh -i terraform/qr-forge.pem ubuntu@<instance-ip>

# View Docker logs
cd /opt/qr-forge
docker-compose logs -f
```

### Restart Application

```bash
# From local machine
ssh -i terraform/qr-forge.pem ubuntu@<instance-ip> \
  'cd /opt/qr-forge && docker-compose restart'
```

### Update Application

```bash
# SSH into server
ssh -i terraform/qr-forge.pem ubuntu@<instance-ip>

# Pull latest changes
cd /opt/qr-forge/app
git pull origin main

# Rebuild and restart
cd /opt/qr-forge
docker-compose up -d --build
```

## 🧹 Cleanup

### To Destroy All Resources

```bash
cd terraform
terraform destroy

# Confirm with 'yes'
```

This will remove:
- EC2 instance
- VPC and networking
- Security groups
- Elastic IP
- S3 bucket (if empty)

**Note:** S3 bucket with contents must be emptied manually before destruction.

## 💰 Cost Estimation

### Monthly AWS Costs (us-east-1)

| Resource | Cost |
|----------|------|
| EC2 t2.micro | ~$8.50/month (or FREE tier) |
| Elastic IP | $3.60/month (if instance stopped) |
| S3 Storage (5GB) | ~$0.12/month |
| Data Transfer (minimal) | ~$0.50/month |
| **Total** | **~$12.72/month** |

**Note:** First year is mostly free with AWS Free Tier!

## 🐛 Troubleshooting

### Issue: Terraform apply fails

```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify Terraform syntax
terraform validate
```

### Issue: Can't SSH into instance

```bash
# Check security group allows your IP
# Update terraform/main.tf security group if needed

# Verify key permissions
chmod 400 terraform/qr-forge.pem
```

### Issue: Application not accessible

```bash
# Check if containers are running
./scripts/health-check.sh

# View container logs
ssh -i terraform/qr-forge.pem ubuntu@<ip> \
  'docker logs qr-forge'
```

### Issue: Docker build fails

```bash
# SSH into server and check Docker
ssh -i terraform/qr-forge.pem ubuntu@<ip>
docker ps -a
docker logs <container-id>

# Check disk space
df -h
```

## 📖 Learning Resources

### DevOps Concepts Demonstrated
- ✅ Infrastructure as Code (IaC) with Terraform
- ✅ Configuration Management with Ansible
- ✅ Containerization with Docker
- ✅ Cloud Computing with AWS
- ✅ CI/CD Pipeline basics
- ✅ Bash scripting for automation
- ✅ Version control with Git

### Next Steps
1. **Add SSL/TLS**: Configure Let's Encrypt for HTTPS
2. **Custom Domain**: Set up Route53 for custom domain
3. **CI/CD**: Add GitHub Actions for automated deployments
4. **Monitoring**: Integrate CloudWatch or Prometheus
5. **Load Balancer**: Add ALB for high availability
6. **Auto Scaling**: Configure ASG for traffic handling

## 🤝 Contributing

This is a learning project for my DevOps portfolio. Feel free to:
- Fork and modify for your needs
- Add improvements and submit PRs
- Use as reference for your own projects

## 📝 License

This DevOps pipeline is open source. The QR Forge application maintains its own license.

## 👨‍💻 Author

**Abdulhamid Ejiwumi**
- GitHub: [@iam-ejidek](https://github.com/iam-ejidek)
- LinkedIn: [abdulhamidejiwumi](https://linkedin.com/in/abdulhamidejiwumi)

## 🙏 Acknowledgments

- QR Forge application by [@abdulazeez9](https://github.com/abdulazeez9)
- AWS for cloud infrastructure
- HashiCorp for Terraform
- Red Hat for Ansible
- Docker Inc for containerization platform

---

## 📞 Support

If you encounter any issues:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Review application logs
3. Open an issue on GitHub

---

**Happy DevOps Learning! 🚀**

*This project demonstrates practical DevOps skills including Infrastructure as Code, Configuration Management, Containerization, and Cloud Computing - perfect for showcasing in your portfolio!*
