Absolutely! Here's a complete Step-by-Step Method of Procedure (MOP) for your current ECS Fargate + Terraform + GitHub Actions CI/CD setup with dev, staging, and prod branches:
________________________________________
📘 Method of Procedure (MOP)
Project Title: Multi-Environment ECS Fargate Deployment with Terraform & GitHub Actions
Author: Jomari R. Samson
Environments: dev, staging, prod
App: Dockerized Node.js App
CI/CD: GitHub Actions
Infrastructure as Code: Terraform
________________________________________
✅ Prerequisites
1.	AWS CLI installed and configured (aws configure)
2.	Docker installed
3.	Terraform installed
4.	GitHub account & repo created
5.	Amazon ECR repo created (can be shared or one per env)
6.	IAM User/Role with appropriate permissions
________________________________________
🧱 Step 1: Directory Structure
bash
CopyEdit
aws-devops-portfolio/
├── app/                    # Your Dockerized Node.js App
│   ├── app.js
│   ├── Dockerfile
│   └── package.json
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
________________________________________
⚙️ Step 2: Setup Docker App
app/Dockerfile
Dockerfile
CopyEdit
FROM node:18-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
________________________________________
🌍 Step 3: Create Terraform Code Per Environment
Each folder (dev, staging, prod) must have:
•	main.tf
•	variables.tf
•	outputs.tf
•	provider.tf
🔁 Repeat your current working prod Terraform files for dev and staging, update:
•	Cluster name
•	ECS service name
•	Task family name
•	ECR image (tag as :dev, :staging, :latest)
________________________________________
🔐 Step 4: Configure GitHub Secrets
In your GitHub repo, go to Settings → Secrets and variables → Actions
Create the following secrets:
Name	Value
AWS_ACCESS_KEY_ID	Your AWS access key
AWS_SECRET_ACCESS_KEY	Your AWS secret
AWS_REGION	ap-southeast-1
AWS_ACCOUNT_ID	Your AWS account ID
________________________________________
⚡ Step 5: Setup GitHub Workflows
Example: .github/workflows/dev.yml
yaml
CopyEdit
name: Deploy to Dev

on:
  push:
    branches:
      - dev

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  AWS_ACCOUNT_ID: ${{ secrets.AWS_ACCOUNT_ID }}
  ECR_REPO_NAME: fargate-app
  CLUSTER_NAME: fargate-cluster-dev
  SERVICE_NAME: fargate-service-dev
  TASK_FAMILY: fargate-task-dev

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v3
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ env.AWS_REGION }}

    - name: Login to ECR
      run: |
        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

    - name: Build, Tag, Push Image
      run: |
        docker build -t $ECR_REPO_NAME ./app
        docker tag $ECR_REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:dev
        docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:dev

    - name: Deploy to ECS
      run: |
        aws ecs update-service \
          --cluster $CLUSTER_NAME \
          --service $SERVICE_NAME \
          --force-new-deployment
🔁 Copy this for staging.yml and prod.yml, update:
•	ECR image tag to :staging or :latest
•	ECS cluster/service/task names
________________________________________
🌐 Step 6: Deploy Terraform Infra
Per environment:
bash
CopyEdit
cd terraform/dev
terraform init
terraform apply

cd ../staging
terraform init
terraform apply

cd ../prod
terraform init
terraform apply
☑️ Copy the output alb_dns after apply — this is your app URL.
________________________________________
🚀 Step 7: Workflow In Action
Make code changes to the app:
bash
CopyEdit
git checkout dev
# edit app.js
git add .
git commit -m "Update Dev App"
git push origin dev
✅ This triggers:
•	Docker build
•	Push to ECR with :dev tag
•	ECS Fargate redeploy on dev
🔁 Repeat with staging and prod branches.
________________________________________
📦 Step 8: Add to Portfolio
•	Add README.md with:
o	Architecture diagram
o	Tools used
o	How to deploy and test
•	Add screenshots of:
o	GitHub Actions logs
o	App running on dev, staging, prod URLs
o	Terraform apply output
________________________________________
Let me know if you'd like me to generate the sample README.md or CI/CD diagram next!










Here’s your complete and professional README.md for the project, along with an ASCII-based CI/CD diagram. This is suitable for showcasing in a DevOps portfolio or GitHub repo:
________________________________________
markdown
CopyEdit
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
________________________________________
🔧 Tools & Services Used
•	AWS ECS Fargate
•	AWS Application Load Balancer (ALB)
•	Amazon ECR
•	Terraform
•	GitHub Actions
•	Docker
•	Node.js (app)
________________________________________
🌍 Environments
Branch	ECS Cluster	ECR Image Tag	ALB DNS
dev	fargate-cluster-dev	:dev	Output of terraform apply
staging	fargate-cluster-staging	:staging	Output of terraform apply
prod	fargate-cluster	:latest	Output of terraform apply
________________________________________
📁 Project Structure
bash
CopyEdit
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
________________________________________
⚙️ CI/CD Workflow
Each time a branch is pushed:
1.	GitHub Actions builds Docker image
2.	Tags and pushes it to ECR (:dev, :staging, :latest)
3.	Triggers ECS service update with force new deployment
4.	ECS pulls the new image and deploys it
5.	ALB serves the application
________________________________________
🧪 How to Test
bash
CopyEdit
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
________________________________________
🛡️ GitHub Secrets Required
Name	Description
AWS_ACCESS_KEY_ID	AWS IAM access key
AWS_SECRET_ACCESS_KEY	AWS IAM secret key
AWS_REGION	e.g., ap-southeast-1
AWS_ACCOUNT_ID	Your 12-digit AWS account ID
________________________________________
✅ How to Deploy Terraform
bash
CopyEdit
cd terraform/dev      # or staging/prod
terraform init
terraform apply
________________________________________
📷 Screenshots (optional)
You can upload screenshots of:
•	GitHub Actions logs for each branch
•	ECS task running on AWS console
•	Web app shown via the ALB DNS URL
________________________________________
📌 Author
Jomari R. Samson
📧 zjrsamson07@gmail.com
📍 Sta. Maria, Bulacan
🌐 GitHub: jrstech-ops


