


########################################
# AMI Data Source
########################################
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

########################################
# Jumphost Instance
########################################
resource "aws_instance" "main" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # This resolves the tfsec warning
    http_put_response_hop_limit = 1
  }

  # CRITICAL: Adds the profile we just created in the IAM module
  iam_instance_profile = var.instance_profile_name

  user_data = <<-EOF
              #!/bin/bash
              # Finish Line 2026 - Requirement F: Automated Tooling
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              
              echo "Starting Jumphost Tooling Installation..."
              
              # 1. Update and Base Utils
              dnf update -y
              dnf install -y unzip tar gzip
              
              # 2. Install Database Clients (Requirement F)
              # postgresql15 provides 'psql'
              # mariadb105 provides 'mysql'
              dnf install -y postgresql15 mariadb105 aws-cli
              
              # 3. Install kubectl (Latest Stable)
              K8S_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
              curl -LO "https://dl.k8s.io/release/$${K8S_VERSION}/bin/linux/amd64/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/
              
              # 4. Install Helm 3 (Latest)
              curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
              
              # 5. Install Kustomize (Latest)
              curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
              mv kustomize /usr/local/bin/

              echo "Verification Check:"
              aws --version
              kubectl version --client
              helm version
              kustomize version
              mysql --version
              psql --version
              EOF


  root_block_device {
    encrypted   = true
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.environment}-jumphost"
    Environment = var.environment
    Project     = var.project
    Owner       = "Marcellus"
    ManagedBy   = "terraform"
  }
}

