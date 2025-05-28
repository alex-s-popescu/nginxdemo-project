data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}



resource "aws_instance" "app" {
  depends_on                  = [aws_instance.bastion]
  count                       = 2
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private[count.index].id
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  associate_public_ip_address = false
  key_name                    = var.ssh_key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y aws-cli jq
              
              mkdir -p /home/ec2-user/.ssh
              chown ec2-user:ec2-user /home/ec2-user/.ssh

              # Fetch public key from Secrets Manager
              PUBKEY=$(aws secretsmanager get-secret-value \
                --region ${var.aws_region} \
                --secret-id nginxdemo-bastion-ssh-pubkey \
                --query SecretString --output text)

              echo "$PUBKEY" >> /home/ec2-user/.ssh/authorized_keys
              cat /home/ec2-user/.ssh/authorized_keys | sort | uniq > /tmp/authorized_keys_clean
              mv /tmp/authorized_keys_clean /home/ec2-user/.ssh/authorized_keys
              chown ec2-user:ec2-user /home/ec2-user/.ssh/authorized_keys
              chmod 600 /home/ec2-user/.ssh/authorized_keys

              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              docker run -d -p 80:80 nginxdemos/hello
              EOF
# moving original authorized_keys to tmp and adding new one to avoid removal
# new one is used to ssh nginx ec2s and previous for admin access
  tags = {
    Name = "${var.project_name}-app-${count.index}"
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y aws-cli jq

              ssh-keygen -t rsa -b 2048 -f /root/.ssh/id_rsa -q -N ""
              PUBKEY=$(cat /root/.ssh/id_rsa.pub)

              # Check if the secret exists; create it if it doesn't
              aws secretsmanager describe-secret \
                --region ${var.aws_region} \
                --secret-id nginxdemo-bastion-ssh-pubkey || \
              aws secretsmanager create-secret \
                --region ${var.aws_region} \
                --name nginxdemo-bastion-ssh-pubkey \
                --secret-string "$PUBKEY"

              # Update the secret with the latest public key
              aws secretsmanager put-secret-value \
                --region ${var.aws_region} \
                --secret-id nginxdemo-bastion-ssh-pubkey \
                --secret-string "$PUBKEY"
              EOF

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

# Register EC2s with ALB target group
resource "aws_lb_target_group_attachment" "tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}