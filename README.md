# nginxdemo-project

This project automates the deployment of a stateless, containerized web application using Terraform on AWS. It uses the publicly available Docker image `nginxdemos/hello`, and provisions a highly available, TLS-secured infrastructure with optional SSH access via a Bastion host.

---

## ✨ Features

- Fully automated infrastructure provisioning using Terraform  
- High-availability deployment across two Availability Zones  
- Application Load Balancer (ALB) with HTTPS (TLS) termination  
- ACM certificate issued and validated via Route 53  
- Private subnets for EC2 instances  
- Optional public Bastion host for SSH access  
- Secure Secrets Manager integration for SSH key exchange  
- Fine-grained IAM roles and security groups  

---

## ⚙️ Prerequisites

1. Terraform 1.5.0 or newer  
2. AWS CLI configured with permissions for IAM, EC2, VPC, ACM, Route 53, ELB, and Secrets Manager  
3. An existing domain hosted in Route 53  
4. A valid EC2 key pair name in your AWS account  

---

## 📁 Project Structure

```
nginxdemo-project/
├── main.tf
├── variables.tf
├── outputs.tf
├── alb.tf
├── ec2.tf
├── iam.tf
├── vpc.tf
├── nat.tf
├── certificate.tf
├── security.tf
├── terraform.tfvars
├── cost-estimate.md
├── aws_network_diagram.png
├── architecture-diagram/
├── README.md
├── summary.md
```

---

## 🚀 Usage

### Step 1: Clone the Repository

```bash
git clone https://github.com/alex-s-popescu/nginxdemo-project.git
cd nginxdemo-project
```

### Step 2: Create `terraform.tfvars` File

```hcl
domain_name    = "demo.example.com"
ssh_key_name   = "my-ec2-keypair"
my_ip          = "1.2.3.4/32"
enable_bastion = true
```

### Step 3: Initialize Terraform

```bash
terraform init
```

### Step 4: Review the Plan

```bash
terraform plan
```

### Step 5: Apply and Deploy

```bash
terraform apply
```

---

## 🌐 Access

After successful deployment, visit:  
`https://demo.example.com`

If Bastion is enabled:

```bash
ssh -i ~/your-key.pem ec2-user@<bastion_public_ip>
```

---

## 📤 Terraform Outputs

- `alb_dns_name`: ALB DNS name for the HTTPS app  
- `instance_private_ips`: Internal app EC2 IPs  
- `bastion_public_ip`: SSH access point (if enabled)  
- `acm_certificate_arn`: ACM cert for ALB  
- `hosted_zone_id`: Route 53 zone ID  
- `bastion-ssh-pubkey_secret_arn`: ARN of SSH key in Secrets Manager  

---

## 🔐 TLS & DNS Integration

- ACM requests TLS cert in `us-east-1`  
- Terraform auto-creates DNS CNAME in Route 53  
- Once validated, ACM cert is attached to ALB  
- Route 53 A-record alias points your domain to ALB  

---

## 🔒 Security Highlights

- ALB is internet-facing (HTTPS only)  
- EC2s are in private subnets, not publicly accessible  
- Bastion allows SSH only from your IP  
- Secrets Manager handles Bastion key securely  
- IAM roles are scoped to least-privilege  

---

## 🧼 Cleanup

To remove all infrastructure:

```bash
terraform destroy
```

Then check in the AWS Console:
- EC2, VPC, ELB
- IAM roles and profiles
- Route 53 records
- ACM certificates
- Secrets Manager secrets

---

## 🧠 Tip

ACM validation may take several minutes. If stuck, verify:
- Your domain is hosted in Route 53  
- CNAME validation record exists and matches

---

## 📜 License

MIT License

---

## ✍️ Author

Alex Popescu