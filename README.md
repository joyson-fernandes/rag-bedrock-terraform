# rag-bedrock-terraform

Terraform infrastructure for the [Production RAG on AWS Bedrock](https://github.com/joysontech/rag-bedrock) project.

This is the **infrastructure-as-code alternative** to the console-first approach. The main [rag-bedrock](https://github.com/joysontech/rag-bedrock) repo is console-only — every AWS resource created via the AWS console step by step. This repo contains the equivalent Terraform modules for teams who prefer IaC.

📝 **Blog**: [Build a Production RAG System on AWS Bedrock from Scratch](https://joysonfernandes.medium.com/build-a-production-rag-system-on-aws-bedrock-from-scratch-c6449d4de8e5)

---

## What This Provisions

- VPC with 2 private subnets, security groups, and VPC endpoints
- Aurora Serverless v2 with pgvector
- Lambda functions (Ingest + Query)
- API Gateway HTTP API + Cognito User Pool
- IAM roles and policies
- S3 docs bucket and DynamoDB sessions table

**Not provisioned by Terraform** (created via Bedrock console only):
- Bedrock Guardrails
- Bedrock Prompt Management
- Bedrock Knowledge Bases
- Bedrock Evaluations

## Prerequisites

- Terraform >= 1.9
- AWS CLI configured with admin IAM user
- S3 bucket for Terraform state (update `terraform/backend.tf`)

## Usage

```bash
git clone https://github.com/joyson-fernandes/rag-bedrock-terraform.git
cd rag-bedrock-terraform

# Update terraform/backend.tf with your S3 state bucket
# Update terraform/variables.tf with your settings

make init
make plan
make apply
```

## Module Structure

```
terraform/
├── main.tf           # Root module wiring all modules together
├── variables.tf      # Input variables (region, project name)
├── outputs.tf        # Output values (endpoints, ARNs)
├── providers.tf      # AWS provider configuration
├── backend.tf        # S3 remote state configuration
└── modules/
    ├── networking/   # VPC, subnets, security groups, VPC endpoints
    ├── database/     # Aurora Serverless v2, pgvector, Secrets Manager
    ├── lambda/       # Lambda functions, IAM role, S3 trigger
    └── api/          # API Gateway HTTP API, Cognito User Pool
```

## Lambda Code

The Lambda source code lives in the main [rag-bedrock](https://github.com/joysontech/rag-bedrock) repo under `src/`. Clone that repo and package the Lambdas before running `terraform apply`.

## Destroy

```bash
make destroy
```

> Note: Bedrock resources (Guardrails, Prompt Management, Knowledge Bases, Evaluations) created via the Bedrock console must be deleted manually — they are not managed by this Terraform configuration.

## Related

- [rag-bedrock](https://github.com/joysontech/rag-bedrock) — Console-first build guide (main repo)
- [AIP-C01 Practice Exam](https://github.com/joyson-fernandes/aip-c01-practice-exam) — 75-question practice exam
- [Medium article](https://joysonfernandes.medium.com/build-a-production-rag-system-on-aws-bedrock-from-scratch-c6449d4de8e5)
