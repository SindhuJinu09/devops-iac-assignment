# AWS DevOps / Infrastructure as Code – Small Production Demo

This repository implements the KSTPL DevOps / IaC assignment using Terraform and AWS.

**Candidate:** Sindhu Jinukala

## Architecture

```text
                         Internet
                            |
                         HTTP :80
                            |
                    +----------------+
                    | Public ALB     |
                    +-------+--------+
                            |
              weighted 50/50 forward
                 /                    \
        +---------------+     +---------------+
        | nginx-a TG    |     | nginx-b TG    |
        +-------+-------+     +-------+-------+
                |                     |
        +-------v-------+     +-------v-------+
        | ECS Service A |     | ECS Service B |
        | nginx-a       |     | nginx-b       |
        +-------+-------+     +-------+-------+
                \                     /
                 \                   /
                  +-----------------+
                  | ECS Cluster EC2 |
                  | Private subnet  |
                  +--------+--------+
                           |
                         NAT GW
                           |
                        Internet

Client
  |
  +--> POST /upload
          |
      API Gateway HTTP API
          |
        Lambda
          |
          +--> S3 private bucket
          |
          +--> CloudWatch Logs
```

## Components

- VPC with public, private application and private data subnets across two AZs
- Internet Gateway
- One NAT Gateway
- Application Load Balancer
- ECS cluster using EC2 launch type
- Auto Scaling Group with ECS-optimized Amazon Linux 2 AMI
- Two ECS services: `nginx-a` and `nginx-b`
- Separate target groups with 50/50 weighted ALB forwarding
- API Gateway HTTP API
- Python Lambda upload function
- Private S3 bucket
- IAM least-privilege Lambda S3 permissions
- CloudWatch logs for ECS and Lambda
- GitHub Actions for Terraform fmt/validate/plan

## Prerequisites

- AWS account
- Terraform >= 1.5
- AWS CLI configured
- Git
- An AWS region with at least one available AZ

Verify:

```bash
aws sts get-caller-identity
terraform version
```

Terraform uses the normal AWS credential chain (for example, environment variables, an AWS CLI profile selected with `AWS_PROFILE`, or an attached role). The configuration does not require a profile named `assignment`. The variable default is `ap-south-2`; this demo was deployed in Mumbai (`ap-south-1`), so pass `-var="aws_region=ap-south-1"` to each Terraform plan, apply, and destroy command when reproducing this deployment. Setting the AWS CLI region alone does not override this Terraform variable.

The demo creates billable AWS resources, including a NAT Gateway, EC2 capacity, and a public load balancer. Review the plan and remove the stack with `terraform destroy` after collecting evidence. The upload bucket is configured for destruction with the stack and expires objects under `uploads/` after 30 days.

## Deploy

From the repository root:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var="aws_region=ap-south-1"
terraform apply -var="aws_region=ap-south-1"
```

After apply, Terraform prints:

- ALB DNS name
- Upload API URL
- S3 bucket name
- ECS cluster/service names

## Test nginx load balancing

```bash
curl http://$(terraform output -raw alb_dns_name)/
```

Run multiple requests:

```bash
for i in {1..10}; do
  curl -s http://$(terraform output -raw alb_dns_name)/ | grep -E "nginx-a|nginx-b"
done
```

Because the ALB listener uses weighted forwarding, requests should be distributed between the two target groups.
The 50/50 target-group weights are probabilistic; they do not guarantee that each pair of consecutive requests alternates services. Each target group distributes requests among its registered targets using the ALB's normal behavior.

## Test file upload

Create a test file:

```bash
echo "Hello from Terraform assignment" > test.txt
```

Upload:

```bash
curl -X POST \
  --data-binary @test.txt \
  "$(terraform output -raw upload_api_url)?filename=test.txt"
```

List the object:

```bash
aws s3 ls "s3://$(terraform output -raw upload_bucket_name)/uploads/"
```

The API response contains the generated S3 object key (`key`). To download that exact object, use the returned key:

```bash
aws s3 cp "s3://$(terraform output -raw upload_bucket_name)/<key-from-upload-response>" -
```

## Lambda logs

```bash
aws logs tail "$(terraform output -raw lambda_log_group_name)" --follow
```

## ECS logs

```bash
aws logs tail "$(terraform output -raw ecs_log_group_name)" --follow
```

## Demo evidence

The live demo was deployed in `ap-south-1`. These captures show two required end-to-end checks: requests reaching both nginx services through the ALB, and a successful file upload through API Gateway with the resulting object listed in S3.

### ALB traffic reaches both nginx services

The target health check is healthy, and repeated curl requests return responses from both `nginx-a` and `nginx-b`.

![Healthy ALB target and curl responses from nginx-a and nginx-b](evidence/Screenshot%202026-10-13%20185938.png)

### Upload API stores the file in S3

The upload endpoint returned HTTP 201 with `Upload successful`, and `aws s3 ls` showed the uploaded object under `uploads/`.

![Successful API upload and S3 object listing](evidence/Screenshot%202026-10-13%20190454.png)

The complete set of original screenshots and their descriptions is in [evidence/README.md](evidence/README.md).

## Destroy

When the demo is complete:

```bash
terraform destroy -var="aws_region=ap-south-1"
```

Type `yes` when prompted.

## Notes

This implementation intentionally uses the public `nginx:alpine` image to keep the demo simple. The assignment permits either public nginx or ECR-hosted images.

The API accepts the uploaded file as the raw HTTP request body and uses the `filename` query parameter for the S3 object name. This avoids requiring multipart parsing inside the Lambda while still demonstrating an API file-upload flow.
