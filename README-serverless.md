# Phase 2 — Serverless employee API (Lambda + API Gateway + DynamoDB)

Since the SCP blocks managed RDS, this is the teacher-preferred fallback: a **serverless**
employee API. State lives in **DynamoDB** (managed, outside Kubernetes), served by a **Lambda**
function through an **API Gateway** HTTP endpoint, with **least-privilege IAM**.

```
client ──HTTPS──► API Gateway ──► Lambda (Python) ──IAM──► DynamoDB (employees)
```

## What's in here (drop into your existing Terraform folder)

| File | Creates |
|------|---------|
| `dynamodb.tf` | `innovatech-employees` table (pay-per-request) + 2 seed rows |
| `lambda.tf` | IAM role (least-privilege DynamoDB access) + the Python Lambda |
| `apigateway.tf` | HTTP API, routes, stage, and invoke permission |
| `lambda/handler.py` | The API logic (list / get / onboard / offboard / delete) |
| `lambda/lambda_function.zip` | Pre-built deployment package |
| `outputs-serverless.tf` | `employee_api_url`, `dynamodb_table` |

## Deploy

```powershell
terraform init
terraform plan
terraform apply
```

Note the `employee_api_url` output.

> If `apply` returns `explicit deny ... service control policy` on Lambda or API Gateway, those
> services are blocked too — tell me and we switch to "k3s backend pod talks to DynamoDB via IAM",
> which needs only DynamoDB + IAM (both confirmed allowed).

## Demo / test (PowerShell)

```powershell
$api = "<employee_api_url>"

# List (shows the two seeded employees)
Invoke-RestMethod "$api/employees"

# Onboard a new employee (POST)
$new = Invoke-RestMethod -Method Post "$api/employees" -ContentType application/json `
  -Body '{"name":"Grace Hopper","email":"grace@innovatech.example","department":"Engineering","role":"Developer"}'
$new   # note the generated id

# Offboard them (PATCH status)
Invoke-RestMethod -Method Patch "$api/employees/$($new.id)" -ContentType application/json `
  -Body '{"status":"offboarded"}'

# Verify, then delete
Invoke-RestMethod "$api/employees/$($new.id)"
Invoke-RestMethod -Method Delete "$api/employees/$($new.id)"
```

That sequence is a clean live demo: **onboard -> offboard -> delete**, all serverless, data in DynamoDB.

## How this answers the teacher

- **Stateful data is out of Kubernetes** -> DynamoDB, a managed serverless store.
- **Right tool for the job** -> stateless app in k3s; data in a managed service; serverless API for access.
- **Security** -> the Lambda's IAM role can touch *only* this one table (least privilege); no public DB.
- **His exact suggestion** -> Lambda + managed storage, no servers to manage for the data tier.

## About the Headscale mesh you built

DynamoDB is an API (not a server in a subnet), so it isn't reached through the mesh. The
Headscale + subnet router are still useful for **private admin access to your EC2 nodes** (a valid
Zero Trust story for your report). If you'd rather cut cost, you can `terraform destroy` just those
two instances later — your call.

## Cost

DynamoDB pay-per-request + Lambda + API Gateway are effectively free at demo volumes. The only
ongoing cost is the EC2 nodes (k3s + the two mesh boxes). `terraform destroy` when not working.
