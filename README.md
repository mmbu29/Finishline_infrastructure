Finishline Infrastructure
Production‑ready AWS foundation built with modular Terraform + Terragrunt for scalable, multi‑environment deployments.
This repository implements a clean, extensible, and environment‑consistent AWS infrastructure using Terraform modules, Terragrunt orchestration, and best‑practice AWS architecture patterns. It is designed for teams that need repeatable, secure, and production‑grade cloud environments.

Architecture Overview
┌──────────────────────────────────────────────┐
│                Terragrunt Root               │
│      (remote state, provider config)         │
└──────────────────────────────────────────────┘
│
▼
┌──────────────────────────────────────────────┐
│                Environments                  │
│   dev / staging / prod (isolated configs)    │
└──────────────────────────────────────────────┘
│
▼
┌──────────────────────────────────────────────┐
│                  Modules                     │
│  VPC | ALB | EKS | Aurora | IAM | Jumphost   │
└──────────────────────────────────────────────┘
Each environment (e.g., dev) composes the same modules with different variables, ensuring consistency, repeatability, and safe promotion from dev → staging → prod.

Key Features
Modular Terraform Architecture
Each AWS component is encapsulated in its own reusable module:
- VPC (subnets, routing, NAT, IGW)
- ALB (listeners, target groups, security groups)
- EKS (cluster, node groups, IAM roles)
- Aurora PostgreSQL (serverless or provisioned)
- IAM (roles, policies, least‑privilege patterns)
- Jumphost (bastion for secure access)

Terragrunt for Environment Orchestration
Terragrunt provides:
- DRY configuration using root.hcl
- Remote state management
- Dependency wiring between modules
- Environment isolation (dev, staging, prod)

Production‑grade AWS Patterns
1. Multi‑AZ networking
2. Private subnets for compute + databases
3. Public subnets for ingress
4. Secure IAM role boundaries
5. Encrypted storage and secrets

Git‑clean Infrastructure
.terraform, .terragrunt-cache, provider binaries, and state files are excluded using a clean .gitignore.
Repository Structure
finishline_infrastructure/
│
├── environments/
│   ├── root.hcl
│   ├── env.hcl
│   └── dev/
│       ├── vpc/
│       ├── alb/
│       ├── eks/
│       ├── aurora/
│       ├── iam/
│       └── jumphost/
│
├── modules/
│   ├── vpc/
│   ├── alb/
│   ├── eks/
│   ├── aurora/
│   ├── iam/
│   └── jumphost/
│
└── k8s-manifests/
    └── test-alb.yaml

How to Deploy
1. Install prerequisites
- Terraform ≥ 1.6
- Terragrunt ≥ 0.55
- AWS CLI configured with credentials
2. Navigate to an environment
```
cd environments/dev/vpc
terragrunt init
terragrunt plan
terragrunt apply
```
3. Deploy the full environment
From the environment root:
```
cd environments/dev
terragrunt run-all apply
```

Terragrunt automatically handles:
- Dependency ordering
- Remote state
- Module wiring

Security & Compliance
This infrastructure follows AWS best practices:
- Encrypted S3 backend for Terraform state
- DynamoDB table for state locking
- IAM least‑privilege patterns
- Encrypted EKS secrets
- Encrypted Aurora storage
- No hard‑coded credentials

Testing & Validation
```
terragrunt hclfmt
terraform fmt
terraform validate
```

Optional enhancements:
- Add tfsec for security scanning
- Add Checkov for IaC compliance
- Add GitHub Actions for CI/CD

Future Enhancements
1. Add staging + production environments
2. Add Route53 + ACM for HTTPS
3. Add EKS add‑ons (ALB Ingress Controller, Cluster Autoscaler)
4. Add CloudWatch dashboards + alarms
5. Add CI/CD pipelines (GitHub Actions)

Author
Marcellus Mbu
 Data Engineer & Cloud Database Administrator AWS | Terraform | Terragrunt | PostgreSQL | EKS | VPC Architecture
