# 🚀 ECS Fargate + Terraform + GitHub Actions CI/CD

This project demonstrates how to deploy a containerized Node.js app to **Amazon ECS Fargate** using **Terraform** and automate the CI/CD pipeline using **GitHub Actions**.

---

## 🔧 Tech Stack
- AWS ECS Fargate
- Amazon ECR
- Terraform
- GitHub Actions
- Docker
- Node.js (Express)

---

## 📁 Folder Structure

- `terraform/`: Infrastructure as Code using Terraform
- `app/`: Simple Node.js Docker app
- `.github/workflows/`: CI/CD workflow

---

## 🚀 How It Works

1. **App Code** is pushed to GitHub
2. **GitHub Actions**:
   - Builds Docker image
   - Pushes it to Amazon ECR
   - Deploys to ECS Fargate (new task revision)

---

## 📝 Setup Instructions

1. Configure your AWS credentials in GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `AWS_ACCOUNT_ID`

2. Update `deploy.yml` environment values as needed

3. Push to `main` branch — deployment will trigger automatically

---

## 📸 Screenshot

> Add your AWS Architecture diagram or screenshot here

---

## 🤝 Contributing

Pull requests are welcome!

---

## 📜 License

MIT

