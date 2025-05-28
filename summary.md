## Assumptions

- A domain (e.g., `nginxdemo.com`) has already been registered and is either:
  - fully hosted in AWS Route 53 as a public hosted zone, or
  - correctly delegated to Route 53 by updating its NS (Name Server) records with the domain registrar.
- An AWS Route 53 public hosted zone for the domain exists and is managed in the same AWS account used for deployment.
- The hosted zone is fully managed within the same AWS account used for this Terraform deployment.
- DNS delegation to AWS Route 53 name servers is already in effect.
- An EC2 key pair (e.g., `nginxdemo-keypair`) already exists in the target AWS region and the corresponding `.pem` private key is available locally on the user's machine for SSH access.

# 🌐 nginxdemo-project Summary

This project automates the deployment of a stateless, containerized web application using Terraform on AWS. The application is based on the publicly available Docker image nginxdemos/hello. The infrastructure is designed for high availability, secure networking, optional SSH administration access, and full TLS encryption via AWS ACM.

This project provisions a **highly available**, **secure**, and **fully automated** deployment of a stateless web application (`nginxdemos/hello`) in AWS using **Terraform**. It follows best practices for networking, IAM, DNS, and TLS encryption, with all resources created from code and deployed to the `eu-central-1` region.

---

## 🧩 Key Components

- **Application**: [nginxdemos/hello](https://hub.docker.com/r/nginxdemos/hello)
- **Cloud**: AWS (Free-tier eligible)
- **IaC Tool**: Terraform (modular and reusable)
- **Architecture**:
  - ALB for HTTPS load balancing across AZs
  - Private EC2 instances hosting the Docker app
  - Bastion host in public subnet with SSH access
  - NAT Gateway for private instances to reach the Internet
  - Route53 DNS with automatic ACM validation
  - ACM TLS certificate provisioning (DNS-based)

---

## ✨ Features

- Fully automated infrastructure provisioning using Terraform
- High-availability application deployment across two Availability Zones
- Application Load Balancer (ALB) with HTTPS (TLS) termination
- ACM certificate issuance with automatic DNS validation via Route 53
- Private subnets for EC2 application instances
- Public subnets for ALB and optional Bastion host
- Docker-based deployment of a stateless Hello World application
- Optional SSH access to instances via a locked-down Bastion host
- Fine-grained security using AWS Security Groups and IAM roles
- Visual architecture diagram using mingrammer/diagrams
- Secure SSH setup using Secrets Manager: Bastion host public key is stored securely and fetched by internal EC2s via IAM roles

---

## 🔒 Security Architecture

- **Public Subnet**:
  - Only the Bastion EC2 instance is exposed
  - SSH (port 22) access restricted to user's IP

- **Private Subnets**:
  - EC2 web app instances
  - No direct public access
  - Only HTTPS traffic allowed via ALB SG
  - All outbound traffic routed via NAT Gateway

- **Security Groups**:
  - Bastion SG allows SSH from specific IP
  - App SG allows traffic only from ALB SG
  - Default deny for all else

- **NACLs**:
  - Explicitly allow HTTP/HTTPS ingress and SSH egress on the public subnet
  - Lockdown other traffic per subnet role

---

## 📤 Outputs Explained

- **ALB DNS**: The DNS name of the Application Load Balancer; use this to access the application if DNS is not yet setup.
- **Bastion public IP**: Public IP address of the Bastion host for SSH access.
- **Private EC2 IPs**: Private IP addresses of the EC2 instances running the application.
- **Route53 NS records**: Name server records for the hosted zone; useful for verifying DNS delegation.
- **Certificate ARN and validation status**: Amazon Resource Name of the ACM TLS certificate and its current validation state.

---

## 📡 Domain & HTTPS

- **Domain Used**: `nginxdemo.com` (hosted on Route53)
- **ACM**: Amazon-issued certificate validated via DNS
- **ALB**: HTTPS listener with certificate termination
- **Route53**: A-record alias to ALB

### 🔐 How HTTPS via ACM and Route 53 Works

- ACM issues a TLS certificate for the domain (e.g., `nginxdemo.com`).
- Terraform requests this certificate and retrieves the ARN (Amazon Resource Name).
- ACM provides DNS validation records (CNAME) that must be added to the Route 53 hosted zone.
- Terraform automatically creates these DNS validation records in Route 53.
- Once ACM validates the domain ownership via these DNS records, the certificate becomes active.
- The ALB is configured with an HTTPS listener using this ACM certificate.
- Route 53 A-record alias points the domain to the ALB DNS name, enabling secure HTTPS access.

---

## ⚙️ Access & SSH

- **Bastion Host**:
  - Deployed in a public subnet with a public IP address
  - Accessible only via SSH (port 22) from a trusted IP range (user-defined in variables)
  - EC2 key pair (e.g., `nginxdemo-keypair.pem`) must exist prior to deployment in the target AWS region
  - Private key (`.pem`) must be locally available for initial access

- **Application EC2 Instances**:
  - Deployed in private subnets across multiple Availability Zones
  - Do not have public IP addresses
  - Cannot be accessed directly from the internet

- **Secure Key Distribution via IAM & Secrets Manager**:
  - Bastion's SSH **public key** is stored securely in AWS Secrets Manager
  - IAM role assigned to Bastion EC2 instance allows writing this SSH public key to Secrets Manager
  - IAM role assigned to private application EC2s allows them to **read** the SSH public key from Secrets Manager during provisioning
  - During instance bootstrapping, the retrieved public key is added to the authorized_keys file of the default user (`ubuntu`), enabling secure access from Bastion without manual key distribution

- **No SSH Agent Forwarding Used**:
  - This implementation does **not** rely on agent forwarding
  - SSH key is securely distributed via AWS native services using IAM roles and Secrets Manager, reducing risk of key exposure

### 🔐 Secure Internal SSH Access via IAM and Secrets Manager

This project implements a secure and automated method of enabling SSH access from the Bastion EC2 instance to the internal (private) EC2 instances running the NGINX application — **without manually sharing private keys**. Instead of using traditional SSH key distribution mechanisms or agent forwarding, this solution leverages IAM roles and AWS Secrets Manager for dynamic and secure key exchange.

#### 💡 How It Works

1. **Bastion EC2 generates SSH keypair at boot**:
   - Using a `cloud-init` script (`user_data` in Terraform), the Bastion EC2 instance generates a new SSH keypair during its first boot.
   - The private key remains locally stored in `/root/.ssh/id_rsa`.
   - The public key is uploaded to Secrets Manager as a new secret named `bastion-ssh-pubkey`.

2. **IAM Roles Control Permissions**:
   - Bastion EC2 instance is attached to an IAM Role that allows:
     ```json
     {
       "Effect": "Allow",
       "Action": [
         "secretsmanager:CreateSecret",
         "secretsmanager:PutSecretValue"
       ],
       "Resource": "*"
     }
     ```
   - Application EC2 instances (NGINX hosts) have a separate IAM Role allowing:
     ```json
     {
       "Effect": "Allow",
       "Action": [
         "secretsmanager:GetSecretValue"
       ],
       "Resource": "*"
     }
     ```

3. **App EC2 Instances Pull Key from Secrets Manager**:
   - During their initialization (`user_data`), the app EC2s securely retrieve the Bastion’s SSH public key from Secrets Manager.
   - They then append the retrieved public key to `/home/ubuntu/.ssh/authorized_keys`, allowing SSH access **only** from Bastion’s private key.

4. **Result**:
   - No manual SSH key sharing.
   - No `.pem` file distribution between systems.
   - IAM governs who can publish and retrieve the SSH keys.
   - Revocation can be handled via IAM or by deleting the secret.

#### 📜 Relevant Terraform Snippets

**Bastion EC2:**
```hcl
resource "aws_instance" "bastion" {
  # ...
  user_data = file("${path.module}/scripts/bastion_init.sh")
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name
}
```

**Secrets Manager resource:**
```hcl
resource "aws_secretsmanager_secret" "bastion_ssh_public_key" {
  name = "bastion-ssh-pubkey"
}
```

**Secret Version (public key upload):**
```hcl
resource "aws_secretsmanager_secret_version" "bastion_ssh_public_key_version" {
  secret_id     = aws_secretsmanager_secret.bastion_ssh_public_key.id
  secret_string = file("/root/.ssh/id_rsa.pub") # auto-created by bastion
}
```

**App EC2 IAM Role Policy:**
```hcl
resource "aws_iam_policy" "read_ssh_pubkey" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = ["secretsmanager:GetSecretValue"],
      Effect = "Allow",
      Resource = "*"
    }]
  })
}
```

**App EC2 Bootstrap Command:**
```bash
aws secretsmanager get-secret-value --secret-id bastion-ssh-pubkey --query 'SecretString' --region eu-central-1 --output text >> /home/ubuntu/.ssh/authorized_keys
```

This design ensures **secure, ephemeral, and automated SSH access** across EC2 instances within the project.

- **Example Workflow**:
  ```bash
  # Step 1: SSH into Bastion
  ssh -i nginxdemo-keypair.pem ubuntu@<bastion_public_ip>

  # Step 2: From Bastion, SSH into one of the private EC2 app instances
  ssh ubuntu@<private_ec2_ip>
  ```

---

## 🧪 Validation & Monitoring

- **Terraform Outputs**:
  - ALB DNS
  - Bastion public IP
  - Private EC2 IPs
  - Route53 NS records
  - Certificate ARN and validation status

- **Validation Scripts** (optional):
  - Check CNAME DNS propagation
  - Live ACM validation status
  - Use `dig`, `jq`, `aws` CLI

---

## ⚙️ Prerequisites

- An AWS account with appropriate permissions for EC2, Route 53, ACM, IAM, and Secrets Manager.
- AWS CLI configured with credentials.
- Terraform installed locally.
- Registered domain delegated to Route 53.
- EC2 key pair created in the target region.
- Basic knowledge of AWS and Terraform.

---

## 📁 Project Structure

```
nginxdemo-project/
├── main.tf
├── variables.tf
├── outputs.tf
├── scripts/
│   ├── bastion_init.sh
│   └── app_init.sh
├── modules/
│   ├── vpc/
│   ├── ec2/
│   └── alb/
└── README.md
```

---

## ⚙️ Usage Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/nginxdemo-project.git
   cd nginxdemo-project
   ```
2. Initialize Terraform:
   ```bash
   terraform init
   ```
3. Review and customize variables in `variables.tf` if necessary.
4. Apply the Terraform plan:
   ```bash
   terraform apply
   ```
5. Confirm the outputs and access the application via the ALB DNS or your domain.

---

## 📦 Deploy Instructions

1. Set up AWS credentials
2. Clone the repo and run:
   ```bash
   terraform init
   terraform apply
   ```
3. Visit `https://nginxdemo.com` after DNS and cert propagate

---

## ✅ Status

- HTTPS ✅
- Bastion SSH ✅
- NGINX page visible ✅
- DNS propagates correctly ✅
- Security rules enforced ✅
- Infra can be destroyed with `terraform destroy`

---

## 🚧 Notes

- Ensure your domain is correctly delegated to Route53 NS
- If `terraform apply` fails due to IAM or cert issues, validate permissions:
  - `acm:RequestCertificate`, `acm:AddTagsToCertificate`, `route53:ChangeResourceRecordSets`, etc.
- If a `terraform apply` fails with `EntityAlreadyExists` for resources like IAM roles or instance profiles (e.g., `nginxdemo-ec2-role`), either manually remove the conflicting resource via the AWS Console or import it into Terraform using:
  ```bash
  terraform import aws_iam_instance_profile.ec2_instance_profile nginxdemo-ec2-profile
  terraform import aws_iam_role.ec2_role nginxdemo-ec2-role
  ```

---

## 🧼 Cleanup Instructions

To clean up all resources created by this project, run:

```bash
terraform destroy
```

This will remove all AWS resources provisioned by Terraform in this project.

---

## ✅ Extra Precautionary Checks After Cleanup

- Verify Route 53 hosted zone records are removed if no longer needed.
- Check ACM certificates and delete unused ones.
- Confirm EC2 key pairs and IAM roles no longer in use.
- Inspect Secrets Manager for any lingering secrets related to this project and delete if necessary.

---

## 🧠 Tip

Always back up your Terraform state files and sensitive credentials before making major changes or destroying infrastructure.

---

## 📜 License

This project is licensed under the MIT License. See the LICENSE file for details.

---

## ✍️ Author

Alex — nginxdemo-project-test, May 2025