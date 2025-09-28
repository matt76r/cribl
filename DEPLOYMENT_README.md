# Dynamic Firehose Deployment Scripts

## Quick Start

### 1. Simple Deployment (4 parameters)
```bash
# Plan deployment
./simple-deploy.sh webapp application s3 dev

# Deploy resources
./simple-deploy.sh webapp application s3 dev apply

# Destroy resources
./simple-deploy.sh webapp application s3 dev destroy
```

### 2. Full Deployment (with options)
```bash
# Basic deployment
./deploy-firehose.sh -p webapp -l application -d s3 -e prod -a apply

# With Cribl Cloud
./deploy-firehose.sh -p security -l audit -d cribl -e prod \
  --cribl-url "https://in.cribl.cloud/sources/http/abc123" \
  --cribl-client-id "your-client-id" \
  --cribl-client-secret "your-secret" \
  -a apply --auto-approve
```

## Scripts Overview

| Script | Purpose | Usage |
|--------|---------|-------|
| `simple-deploy.sh` | Quick 4-parameter deployment | `./simple-deploy.sh <project> <log> <dest> <env> [action]` |
| `deploy-firehose.sh` | Full-featured deployment | `./deploy-firehose.sh -p proj -l log -d dest -e env [options]` |
| `validate-params.sh` | Validate parameters | `./validate-params.sh <project> <log> <dest> <env>` |
| `list-resources.sh` | List all Firehose resources | `./list-resources.sh` |
| `check-status.sh` | Check specific deployment | `./check-status.sh <project> <log> <dest> <env>` |
| `cleanup.sh` | Clean up specific deployment | `./cleanup.sh <project> <log> <dest> <env>` |
| `batch-deploy.sh` | Deploy multiple configurations | `./batch-deploy.sh` |

## Examples

### Development Environment
```bash
# Validate first
./validate-params.sh webapp application s3 dev

# Deploy
./simple-deploy.sh webapp application s3 dev apply

# Check status
./check-status.sh webapp application s3 dev
```

### Production with Cribl
```bash
./deploy-firehose.sh \
  -p webapp -l api -d cribl -e prod \
  --cribl-url "https://in.cribl.cloud/sources/http/your-id" \
  --cribl-client-id "client-id" \
  --cribl-client-secret "client-secret" \
  -a apply --auto-approve
```

### Batch Deployment
Edit `batch-deploy.sh` to define your deployments, then:
```bash
./batch-deploy.sh
```

## Resource Naming

All resources follow the pattern: `{project}-{log}-{destination}-{environment}`

Examples:
- `webapp-application-s3-dev-firehose-data` (S3 bucket)
- `webapp-application-s3-dev-delivery-stream` (Firehose stream)
- `webapp-application-s3-dev-firehose-delivery-role` (IAM role)

## Troubleshooting

1. **Validate parameters first**: `./validate-params.sh project log dest env`
2. **Check AWS credentials**: `aws sts get-caller-identity`
3. **List existing resources**: `./list-resources.sh`
4. **Check deployment status**: `./check-status.sh project log dest env`
5. **View Terraform state**: `cd /tmp/terraform-firehose-* && terraform show`

## Cleanup

```bash
# Clean specific deployment
./cleanup.sh webapp application s3 dev

# List remaining resources
./list-resources.sh
```
