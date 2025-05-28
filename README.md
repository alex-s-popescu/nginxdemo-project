nginxdemo-project

This project automates the deployment of a stateless, containerized web application using Terraform on AWS. The application is based on the publicly available Docker image nginxdemos/hello. The infrastructure is designed for high availability, secure networking, optional SSH administration access, and full TLS encryption via AWS ACM.

⸻

✨ Features
	•	Fully automated infrastructure provisioning using Terraform
	•	High-availability application deployment across two Availability Zones
	•	Application Load Balancer (ALB) with HTTPS (TLS) termination
	•	ACM certificate issuance with automatic DNS validation via Route 53
	•	Private subnets for EC2 application instances
	•	Public subnets for ALB and optional Bastion host
	•	Docker-based deployment of a stateless Hello World application
	•	Optional SSH access to instances via a locked-down Bastion host
	•	Fine-grained security using AWS Security Groups and IAM roles
	•	Visual architecture diagram using mingrammer/diagrams
	•	Secure SSH setup using Secrets Manager: Bastion host public key is stored securely and fetched by internal EC2s via IAM roles

⸻

⚙️ Prerequisites

To use this project, ensure you have the following ready:
	1.	Terraform version 1.5.0 or newer installed.
	2.	AWS CLI configured with an access key and secret key that has permission to create IAM, EC2, VPC, ACM, Route53, and ELB resources.
	3.	An existing domain name hosted in Route 53 (public hosted zone).
	4.	A valid EC2 key pair name created in your AWS account (for SSH access).

⸻

📁 Project Structure

nginxdemo-project/
├── alb.tf
├── architecture-diagram/
│   └── architecture.py
├── aws_network_diagram.png
├── certificate.tf
├── cost-estimate.md
├── ec2.tf
├── iam.tf
├── main.tf
├── nat.tf
├── outputs.tf
├── README.md
├── security.tf
├── summary.md
├── terraform.tfvars
├── variables.tf
├── vpc.tf


⸻

⚙️ Usage Instructions

Step 1: Clone the Repository

git clone https://github.com/alex-s-popescu/nginxdemo-project
cd nginxdemo-project

Step 2: Configure Your Terraform Inputs

Create a terraform.tfvars file at the root of the project. This will specify all required inputs:

domain_name    = "demo.example.com"         # Your domain hosted in Route 53
ssh_key_name   = "my-ec2-keypair"           # EC2 key pair name
my_ip          = "1.2.3.4/32"               # Your IP address in CIDR format for SSH
enable_bastion = true                       # Optional: create SSH Bastion host

Step 3: Initialize Terraform

This step downloads the necessary providers and initializes the backend.

terraform init

Step 4: Validate and Plan the Infrastructure

Before applying, validate your setup:

terraform plan

Check that all resources will be created correctly, especially the ACM certificate and DNS validation.

Step 4.5: Ensure Bastion Public Key in Secrets Manager

Terraform automatically creates a Secrets Manager entry named `bastion-ssh-pubkey`. Internal EC2 instances are granted IAM roles that allow them to fetch this public key at launch for secure SSH access. No need for agent forwarding or manual distribution.

Step 5: Apply and Deploy

Provision the infrastructure by running:

terraform apply

Approve the plan when prompted. Terraform will create:
	•	VPC and subnets
	•	Security groups
	•	IAM roles
	•	EC2 instances
	•	ALB with HTTPS
	•	ACM certificate with DNS validation

This process may take a few minutes, especially for ACM validation to complete.

⸻

🌐 Accessing the Application

After successful deployment, Terraform will output useful information:

Outputs:
  alb_dns_name = hello-alb-xyz.eu-central-1.elb.amazonaws.com
  instance_private_ips = ["10.0.1.12", "10.0.2.34"]
  bastion_public_ip = 3.122.45.67

Open the ALB DNS name in your browser:

https://demo.example.com

You should see the NGINX Hello World page served over HTTPS.

If enable_bastion = true, you can SSH into the Bastion:

ssh -i ~/your-key.pem ec2-user@<bastion_public_ip>

Internal EC2 instances retrieve the Bastion public key from Secrets Manager during launch and authorize it for SSH access; this allows the Bastion host to SSH directly into app EC2s using the private key it generated at boot time.

⸻


📤 Outputs Explained
	•	alb_dns_name → Public ALB URL for the application (HTTPS)
	•	instance_private_ips → IPs of private EC2 instances running the app
	•	instance_azs → Availability Zones where EC2s are placed
	•	bastion_public_ip → Public IP of Bastion (if created)
	•	acm_certificate_arn → ARN of the ACM certificate issued for your domain, used by the ALB for HTTPS
	•	hosted_zone_id → The ID of the Route 53 hosted zone corresponding to your domain
	•	alb_zone_id → Zone ID of the ALB, used when configuring Route 53 alias records
	•	app_security_group_id → The security group ID associated with the EC2 application instances
	•	bastion-ssh-pubkey_secret_arn → ARN of the AWS Secrets Manager secret containing Bastion host's SSH public key
	•	bastion_instance_id → The instance ID of the Bastion host EC2, useful for automation and audit purposes

---

### 🔐 How HTTPS via ACM and Route 53 Works

To serve the application securely over HTTPS, the following services and DNS mechanisms are configured automatically by Terraform:

1. **ACM (AWS Certificate Manager)**  
   ACM is used to request a TLS certificate for your application domain (e.g., `demo.example.com`). The certificate is provisioned in the `us-east-1` region as required for use with ALB.

2. **ACM Certificate ARN**  
   The ARN (Amazon Resource Name) uniquely identifies the certificate resource. This ARN is attached to the Application Load Balancer (ALB) listener to enable TLS termination.

3. **Route 53 Public Hosted Zone**  
   Your domain must be hosted in Route 53. Terraform queries the existing hosted zone and creates a CNAME record used for ACM DNS validation.

4. **CNAME for Validation**  
   ACM provides a unique CNAME record which must be present in the domain's DNS for ownership validation. Terraform automatically creates this record in Route 53, completing domain verification.

5. **A Record (Alias)**  
   Terraform creates a Route 53 A record that maps your domain (e.g., `demo.example.com`) to the ALB's DNS name using an alias target. This ensures end users can access the app securely using your custom domain.

Once the ACM certificate is validated and attached, the ALB listener is configured to accept only HTTPS traffic (port 443) using that certificate, providing encrypted access to your containerized NGINX application.

---


⸻

🔒 Security Notes
	•	ALB is internet-facing and accepts HTTPS only
	•	EC2s are in private subnets and only reachable via ALB
	•	Security Groups enforce least-privilege access:
	•	ALB SG allows 443 from the world
	•	App SG allows 80 only from ALB
	•	Bastion SG allows SSH only from your IP
	•	IAM roles are scoped with minimal permissions
	•	TLS cert is automatically issued via ACM and validated via Route 53
	•	Bastion public key is stored in AWS Secrets Manager and securely fetched by internal EC2 instances via IAM role permissions
	•	Bastion generates its own SSH keypair at boot and stores the public key in Secrets Manager; this key is used for internal SSH from bastion to app EC2s

⸻

🧼 Cleanup Instructions

To remove all resources:

terraform destroy

This will delete:
	•	All EC2 instances and EBS volumes
	•	ALB and target groups
	•	IAM roles and instance profiles
	•	Subnets, route tables, VPC
	•	Bastion (if created)

⸻

✅ Extra Precautionary Checks After Cleanup

After running `terraform destroy`, double-check the following in the AWS Console to ensure no orphaned resources remain:

- **EC2** → No running or stopped instances under "Instances"
- **Load Balancers** → No ALBs or target groups left under EC2 > Load Balancing
- **VPC** → Your custom VPC, subnets, and route tables are gone under "Your VPCs"
- **IAM** → The IAM roles and instance profiles (e.g., `nginxdemo-ec2-role`) are deleted under "Roles" and "Instance Profiles"
- **ACM** → Certificate issued for your domain is deleted from ACM
- **Route 53** → If applicable, confirm the A record or validation CNAME is removed from the hosted zone

These are optional, but good hygiene practices when working with infrastructure automation.

⸻

🧠 Tip

ACM certificate validation may take a few minutes. If validation fails, check:
	•	Domain is correctly hosted in Route 53
	•	Terraform created the DNS CNAME correctly

⸻

📜 License

MIT License or your preferred open-source license.

⸻

✍️ Author

Alex Popescu