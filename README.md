# 🚀 Multi-Environment ECS Fargate Deployment with Terraform & GitHub Actions

This project demonstrates a fully automated CI/CD pipeline that deploys a Dockerized Node.js app to **Amazon ECS Fargate** across three environments: `dev`, `staging`, and `prod`. It uses **Terraform** for infrastructure provisioning and **GitHub Actions** for continuous integration and deployment.

---

## 📐 Architecture Overview

```text
┌───────────────┐         ┌────────────────────┐
│ GitHub Repo   │  Push   │ GitHub Actions     │
│ (dev/staging/ │ ──────▶ │ CI/CD Pipelines    │
│ prod branches)│         │ (dev.yml, etc.)    │
└───────────────┘         └────────────────────┘
                                │
                                ▼
                        ┌───────────────┐
                        │ Build & Push │
                        │ Docker Image │
                        │  to ECR      │
                        └───────────────┘
                                │
                                ▼
                        ┌───────────────────┐
                        │ Terraform Infra   │
                        │ (VPC, ALB, ECS,   │
                        │ Auto Scaling)     │
                        └───────────────────┘
                                │
                                ▼
                     ┌────────────────────────┐
                     │ ECS Fargate Service    │
                     │ with Load Balancer     │
                     └────────────────────────┘
                                │
                                ▼
                        🌐 Public ALB DNS
🔧 Tools & Services Used
AWS ECS Fargate

AWS Application Load Balancer (ALB)

Amazon ECR

Terraform

GitHub Actions

Docker

Node.js (app)

🌍 Environments
Branch	ECS Cluster	ECR Image Tag	ALB DNS
dev	fargate-cluster-dev	:dev	Output of terraform apply
staging	fargate-cluster-staging	:staging	Output of terraform apply
prod	fargate-cluster	:latest	Output of terraform apply

📁 Project Structure
bash
Copy
Edit
aws-devops-portfolio/
├── app/                        # Node.js App with Dockerfile
├── terraform/
│   ├── dev/
│   ├── staging/
│   └── prod/
├── .github/
│   └── workflows/
│       ├── dev.yml
│       ├── staging.yml
│       └── prod.yml
└── README.md
⚙️ CI/CD Workflow
Each time a branch is pushed:

GitHub Actions builds Docker image

Tags and pushes it to ECR (:dev, :staging, :latest)

Triggers ECS service update with force new deployment

ECS pulls the new image and deploys it

ALB serves the application

🧪 How to Test
bash
Copy
Edit
# Test Dev
git checkout dev
echo "console.log('Hello from Dev')" >> app/app.js
git commit -am "Update Dev App"
git push origin dev

# Test Staging
git checkout staging
echo "console.log('Hello from Staging')" >> app/app.js
git commit -am "Update Staging App"
git push origin staging

# Test Prod
git checkout prod
echo "console.log('Hello from Prod')" >> app/app.js
git commit -am "Update Prod App"
git push origin prod
Then, open the ALB DNS URL (from terraform output alb_dns) in your browser to verify.

🛡️ GitHub Secrets Required
Name	Description
AWS_ACCESS_KEY_ID	AWS IAM access key
AWS_SECRET_ACCESS_KEY	AWS IAM secret key
AWS_REGION	e.g., ap-southeast-1
AWS_ACCOUNT_ID	Your 12-digit AWS account ID

✅ How to Deploy Terraform

cd terraform/dev      # or staging/prod
terraform init
terraform apply
📷 Screenshots (optional)
You can upload screenshots of:

GitHub Actions logs for each branch

ECS task running on AWS console

Web app shown via the ALB DNS URL

📌 Author
Jomari R. Samson
📧 zjrsamson07@gmail.com
📍 Sta. Maria, Bulacan
🌐 GitHub: jrstech-ops
