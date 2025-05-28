from diagrams import Diagram, Cluster, Edge
from diagrams.aws.network import VPC, InternetGateway, NATGateway, ElbApplicationLoadBalancer
from diagrams.aws.compute import EC2
from diagrams.aws.security import IAMRole, SecretsManager
from diagrams.aws.general import General
from diagrams.onprem.network import Internet
from diagrams.aws.security import CertificateManager
from diagrams.onprem.client import Client
from diagrams.aws.network import Route53

def create_diagram(filename="aws_network_diagram"):
    with Diagram("AWS Network Architecture - NGINX HA + Bastion", show=True, direction="TB", filename=filename, outformat="png"):
        internet = Internet("Internet")
        admin = Client("Admin")

        with Cluster("Route 53"):
            dns = Route53("DNS (nginxdemo.com)")

        with Cluster("AWS VPC"):
            vpc = VPC("Main VPC")
            igw = InternetGateway("Internet Gateway")

            with Cluster("Public Subnets"):
                with Cluster("AZ A"):
                    bastion = EC2("Bastion Host")

                with Cluster("AZ B"):
                    pass

                alb = ElbApplicationLoadBalancer("ALB\n(HTTPS + HTTP->302)")
                natgw_public = NATGateway("NAT Gateway (Public)")

            with Cluster("Private Subnets"):
                natgw_private = NATGateway("NAT Gateway (Private)")
                with Cluster("AZ A"):
                    ec2_1 = EC2("App EC2 A")
                    bastion_private = EC2("Bastion Host (Private)")

                with Cluster("AZ B"):
                    ec2_2 = EC2("App EC2 B")

            iam_role = IAMRole("IAM Role")
            cert_mgr = CertificateManager("ACM")
            secrets_mgr = SecretsManager("Secrets Manager\n(Bastion SSH Pubkey)")

        # Inbound ALB HTTPS/HTTP flow
        internet >> Edge(label="HTTPS + HTTP", style="bold", color="black") >> alb
        alb >> Edge(label="Routes to", style="bold", color="black") >> [ec2_1, ec2_2]

        # Admin SSH to Bastion
        admin >> Edge(label="SSH", style="dashed", color="blue") >> igw
        igw >> Edge(label="SSH", style="dashed", color="blue") >> bastion


        bastion_private >> Edge(label="SSH", style="dashed", color="blue") >> ec2_1
        bastion_private >> Edge(label="SSH", style="dashed", color="blue") >> ec2_2

        # NAT Gateway internet egress
        ec2_1 >> Edge(label="Outbound via NAT Private", color="orange") >> natgw_private
        ec2_2 >> Edge(label="Outbound via NAT Private", color="orange") >> natgw_private
        natgw_private >> Edge(label="Outbound via NAT Public", color="orange") >> natgw_public
        natgw_public >> Edge(label="Outbound via Internet", color="orange")>> igw
        igw >> Edge(label="Outbound via Internet", color="orange") >> internet

        # IAM Role usage
        ec2_1 >> Edge(label="Assumes Role") >> iam_role
        ec2_2 >> Edge(label="Assumes Role") >> iam_role
        bastion >> Edge(label="Assumes Role") >> iam_role
    

        # Secrets Manager SSH pubkey flow
        bastion >> Edge(label="Stores SSH pubkey", color="green") >> secrets_mgr
        secrets_mgr >> Edge(label="Fetches pubkey", color="green") >> ec2_1
        secrets_mgr >> Edge(label="Fetches pubkey", color="green") >> ec2_2

        # ACM DNS, ALB flows
        cert_mgr << Edge(label="DNS CNAME", color="red") >> dns 
        dns >> Edge(label="DNS A record ALB", color="red")>> alb
        cert_mgr >> Edge(label="certificate", color="red")>> alb

if __name__ == "__main__":
    create_diagram()