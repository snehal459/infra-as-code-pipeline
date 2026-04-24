# infra-as-code-pipeline

A production-grade CI/CD pipeline that builds, pushes, and deploys a containerized Flask app to AWS ECS Fargate using Terraform and GitHub Actions.

---

## Architecture Diagram

```
                        GitHub Actions
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
     terraform-lint       build            deploy
     (validate+tflint)  (Docker+ECR)    (ECS Fargate)
                                              │
                    ┌─────────────────────────┤
                    │                         │
               PR → staging           push → approve-prod
                                             │
                                        deploy-prod
                                             │
                                    (rollback on failure)

AWS Infrastructure:
┌─────────────────────────────────────────────────┐
│                    VPC (default)                │
│                                                 │
│   ┌──────────┐     ┌──────────┐                 │
│   │  ALB SG  │────▶│  ECS SG  │                 │
│   └──────────┘     └──────────┘                 │
│        │                │                       │
│   ┌────▼─────┐    ┌─────▼──────┐                │
│   │   ALB    │    │ ECS Fargate│                │
│   │ (port 80)│    │ (port 5000)│                │
│   └──────────┘    └─────┬──────┘                │
│                         │                       │
│                  ┌──────▼──────┐                │
│                  │  CloudWatch │                │
│                  │    Logs     │                │
│                  └─────────────┘                │
└─────────────────────────────────────────────────┘

Remote State:
  S3 bucket: infra-as-code-tfstate-458255180443
  DynamoDB:  terraform-lock
```

---

## Pipeline Flow

```
Push to any branch
       │
       ▼
terraform-lint ──── terraform validate + tflint
       │
       ▼
build ──────────── docker build → ECR push
       │
       ├── PR → deploy-staging (auto)
       │
       └── push to main → approve-prod (manual) → deploy-prod → rollback (on failure)
```

---

## Terraform Modules

| Module      | Description                                      |
|-------------|--------------------------------------------------|
| networking  | Uses default VPC and subnets                     |
| security    | ALB and ECS security groups                      |
| compute     | ECR, ECS cluster, task definition, ALB, autoscaling |
| monitoring  | CloudWatch alarms for CPU, memory, ALB 5XX       |

---

## Setup Instructions

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform >= 1.0
- Docker
- GitHub account

### 1. Clone the repo
```bash
git clone https://github.com/snehal459/infra-as-code-pipeline.git
cd infra-as-code-pipeline
```

### 2. Set GitHub Secrets
Go to `Settings → Secrets → Actions` and add:
| Secret | Value |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |

### 3. Set up GitHub Environment for approval gate
Go to `Settings → Environments → New environment` → name it `production` → add required reviewers.

### 4. Initialize Terraform
```bash
cd terraform/envs/dev
terraform init
terraform plan -var="ecr_image=<your-ecr-image-url>"
terraform apply -var="ecr_image=<your-ecr-image-url>"
```

### 5. Push to GitHub
```bash
git add .
git commit -m "initial commit"
git push origin main
```

---

## Runbook

### Pipeline fails at terraform-lint
- Check `terraform validate` output for syntax errors
- Run `tflint` locally: `tflint --chdir=terraform/envs/dev`

### Pipeline fails at build
- Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets are set
- Check ECR repository exists: `aws ecr describe-repositories --region ap-south-1`

### Pipeline fails at deploy
- Check ECS cluster is active: `aws ecs describe-clusters --clusters my-cluster`
- Check ECS service status: `aws ecs describe-services --cluster my-cluster --services my-service`
- Check CloudWatch logs: `/ecs/my-app` log group

### Manual rollback
```bash
PREV=$(aws ecs list-task-definitions --family-prefix my-task --sort DESC --max-items 2 --query "taskDefinitionArns[1]" --output text)
aws ecs update-service --cluster my-cluster --service my-service --task-definition $PREV --force-new-deployment --region ap-south-1
```

### Terraform state issues
```bash
cd terraform/envs/dev
terraform init -reconfigure
terraform refresh -var="ecr_image=<your-ecr-image-url>"
```

---

## Cost Estimate

| Resource | Details | Est. Monthly Cost |
|----------|---------|-------------------|
| ECS Fargate | 2 tasks × 0.25 vCPU × 0.5GB, 24/7 | ~$15 |
| ALB | 1 ALB, low traffic | ~$18 |
| ECR | 1 repo, ~500MB storage | ~$0.05 |
| CloudWatch | Logs + alarms | ~$2 |
| S3 (remote state) | < 1MB state file | ~$0.01 |
| DynamoDB (lock table) | On-demand, minimal requests | ~$0.01 |
| **Total** | | **~$35/month** |

> Costs are estimates based on ap-south-1 pricing. Use [AWS Pricing Calculator](https://calculator.aws) for exact figures.

---

## Tech Stack

- **App**: Python Flask
- **Container**: Docker
- **Registry**: Amazon ECR
- **Orchestration**: Amazon ECS Fargate
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **State**: S3 + DynamoDB
- **Monitoring**: CloudWatch
