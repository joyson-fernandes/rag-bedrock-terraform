# Post-Apply: Update Query Lambda with Bedrock Resource IDs

After running `terraform apply`, run the following commands to wire the
Bedrock resources into the Query Lambda environment variables.

## Get Terraform outputs

```bash
cd terraform
terraform output
```

Expected output:
```
guardrail_id     = "xxxxxxx"
guardrail_version = "1"
prompt_arn       = "arn:aws:bedrock:eu-west-2:ACCOUNT:prompt/PROMPTID:1"
knowledge_base_id = "KBID"
```

## Update Lambda environment variables

```bash
aws lambda update-function-configuration \
  --function-name rag-bedrock-query \
  --environment 'Variables={
    GUARDRAIL_ID=YOUR_GUARDRAIL_ID,
    GUARDRAIL_VERSION=1,
    PROMPT_ARN=YOUR_PROMPT_ARN,
    KNOWLEDGE_BASE_ID=YOUR_KB_ID
  }' \
  --region eu-west-2
```

## Sync the Knowledge Base

After uploading documents to S3, sync the Knowledge Base:

```bash
# Get the data source ID
KB_ID=$(cd terraform && terraform output -raw knowledge_base_id)
DS_ID=$(cd terraform && terraform output -raw data_source_id)

# Start ingestion sync
aws bedrock-agent start-ingestion-job \
  --knowledge-base-id $KB_ID \
  --data-source-id $DS_ID \
  --region eu-west-2

# Check sync status
aws bedrock-agent get-ingestion-job \
  --knowledge-base-id $KB_ID \
  --data-source-id $DS_ID \
  --ingestion-job-id INGESTION_JOB_ID \
  --region eu-west-2
```

## Run a Bedrock Evaluation job

Bedrock evaluation jobs are one-off runs and not managed as persistent
Terraform resources. Run them via the AWS CLI after apply:

```bash
EVAL_ROLE=$(cd terraform && terraform output -raw eval_role_arn)
BUCKET=$(cd terraform && terraform output -raw docs_bucket)

aws bedrock create-evaluation-job \
  --job-name "rag-bedrock-eval-v1" \
  --job-description "LLM-as-judge: Sonnet evaluates Haiku on 8 AIP-C01 questions" \
  --role-arn $EVAL_ROLE \
  --evaluation-config file://docs/eval-config-example.json \
  --inference-config file://docs/inference-config-example.json \
  --output-data-config "{\"s3Uri\":\"s3://$BUCKET/evals/results/\"}" \
  --region eu-west-2
```

> Update `docs/eval-config-example.json` and `docs/inference-config-example.json`
> with your actual bucket name and Knowledge Base ID before running.
