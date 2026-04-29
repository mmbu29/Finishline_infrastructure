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
    http_tokens                 = "required" 
    http_put_response_hop_limit = 1
  }

  iam_instance_profile = var.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash
    # Finish Line 2026 - Requirement F: Automated Tooling
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    set -e

    echo "Starting Jumphost Tooling Installation..."

    ########################################
    # 1. Network & Repo Preparation
    ########################################
    until ping -c 1 google.com &>/dev/null; do 
      echo "Waiting for network connectivity..."
      sleep 2
    done

    dnf clean all
    dnf makecache

    ########################################
    # 2. Install Database Clients (MySQL 8.0 Community)
    ########################################
    echo "Installing Database Clients..."
    
    # Original MySQL Community Repo Requirement
    rpm -Uvh https://repo.mysql.com/mysql80-community-release-el9.rpm
    dnf install -y mysql-community-client
    dnf install -y postgresql15
    dnf install -y aws-cli
    dnf install -y jq git

    ########################################
    # 3. Install kubectl (Latest Stable)
    ########################################
    echo "Installing kubectl..."
    K8S_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/$${K8S_VERSION}/bin/linux/amd64/kubectl"
    install -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl

    ########################################
    # 4. Install Helm 3
    ########################################
    echo "Installing Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    ########################################
    # 5. Install Kustomize
    ########################################
    echo "Installing Kustomize..."
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    install -m 0755 kustomize /usr/local/bin/kustomize
    rm -f kustomize

    ########################################
    # 6. Install eksctl
    ########################################
    echo "Installing eksctl..."
    PLATFORM=$(uname -s)_amd64
    curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$${PLATFORM}.tar.gz"
    tar -xzf eksctl_$${PLATFORM}.tar.gz -C /tmp
    install -m 0755 /tmp/eksctl /usr/local/bin/eksctl
    rm -f eksctl_$${PLATFORM}.tar.gz
    rm -f /tmp/eksctl

    ########################################
    # 7. Quality of Life Configuration
    ########################################
    echo "source <(kubectl completion bash)" >> /home/ec2-user/.bashrc
    echo "alias k=kubectl" >> /home/ec2-user/.bashrc
    echo "complete -o default -F __start_kubectl k" >> /home/ec2-user/.bashrc
    chown ec2-user:ec2-user /home/ec2-user/.bashrc

    ########################################
    # 8. Verification
    ########################################
    echo "Verification Check:"
    aws --version
    kubectl version --client
    helm version --short
    eksctl version
    mysql --version
    psql --version

    echo "Jumphost Tooling Installation Complete."
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