# AWS Cost Estimate Breakdown – nginxdemo-project

This document provides an estimated monthly cost for the infrastructure deployed using Terraform for the `nginxdemo` stateless web application. Costs are calculated assuming usage within the **eu-central-1 (Frankfurt)** region and current AWS pricing as of May 2025.

---

## 📦 Services & Resources

| Component                     | Resource Type                   | Count | Estimated Monthly Cost | Notes                                                             |
|------------------------------|----------------------------------|-------|-------------------------|-------------------------------------------------------------------|
| **EC2 Instances**            | t3.micro (free tier eligible)    | 2     | ~$17.46                | Assumes ~720 hours/month per instance                             |
| **Bastion Host**             | t3.micro                         | 1     | ~$8.73                 | Public subnet, SSH access                                         |
| **EBS Volume**               | gp3, 8 GiB                       | 3     | ~$2.40                 | ~0.10 USD per GB/month                                            |
| **Application Load Balancer**| ALB                              | 1     | ~$18.00                | Includes fixed + LCU-based usage fees                            |
| **Data Transfer (Out)**      | 1 GB/month                       | -     | ~$0.09                 | Minimal traffic for testing                                       |
| **NAT Gateway**              | Managed NAT                      | 1     | ~$34.20                | Per-hour + per-GB charge; not free tier eligible                  |
| **Route 53**                 | Hosted Zone                      | 1     | ~$0.50                 | Public hosted zone fee                                            |
| **ACM Certificate**          | Amazon Issued                    | 1     | $0.00                  | Free for use with ALB                                             |
| **Elastic IP**               | Allocated but used               | 1     | $0.00                  | No cost while attached                                            |
| **Secrets Manager**           | Secret storage (1 secret)        | 1     | ~$0.40                 | Based on ~$0.40 per secret/month                                  |

---

## 💰 Total Estimated Monthly Cost

**~$81.78 USD**

---

## 🧾 Assumptions

- All instances use Amazon Linux 2 or Ubuntu with free-tier eligible instance types.
- Usage remains within ~1 GB of monthly outbound traffic.
- NAT Gateway is necessary for private subnet outbound traffic.
- TLS/HTTPS termination is offloaded to the ALB using an ACM certificate.
- AWS Secrets Manager is used to securely store the Bastion host's SSH public key, accessed by EC2 instances.

- This infrastructure was not built with cost efficiency as the primary goal, but rather to demonstrate high availability (HA) architecture concepts and ease of deployment using Infrastructure as Code (IaC) practices with Terraform.

---

## 💡 Optimization Tips

- **Use EC2 Spot Instances** for non-critical or stateless components.
- **Replace NAT Gateway** with NAT Instance if cost needs to be reduced significantly (~$3–$5/month).
- **Auto-stop EC2** when not in use (e.g., nights/weekends).
- **Monitor Load Balancer LCUs** via CloudWatch to reduce cost.
- **Limit EBS volumes** to only what is needed (8–10 GB typical for web apps).

---

*Note: All pricing subject to change. Always verify with the AWS Pricing Calculator.* 