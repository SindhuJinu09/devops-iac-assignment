# Live demo evidence

Include at least two pieces of evidence from a real deployment in this folder before submitting the repository. Save terminal captures or screenshots here and add their filenames and context below.

## Capture options

1. **ALB responses:** run the loop from the project README several times. Save the commands and actual responses showing both `nginx-a` and `nginx-b`.
2. **S3 upload:** create a small test file, upload it using the API command in the README, then capture the successful API response and `aws s3 ls` result for the uploaded object.
3. **CloudWatch logs (optional additional evidence):** capture relevant Lambda or ECS log lines after the corresponding request.

Use at least two of these options. Preserve timestamps or command context where practical, and exclude AWS credentials, account secrets, and personal data from screenshots.

## Evidence index

| File | What it demonstrates | Date/time (local) |
|---|---|---|
| `Screenshot 2026-10-13 182633.png` | Terraform initialized successfully and installed the Linux AWS, archive, and random providers. | 2026-10-13 18:26 IST |
| `Screenshot 2026-10-13 183722.png` | Terraform apply completed: 56 resources added; outputs include the ALB, ECS services, API URL, S3 bucket, and VPC. | 2026-10-13 18:37 IST |
| `Screenshot 2026-10-13 184701.png` | Both ECS services reported running tasks. | 2026-10-13 18:47 IST |
| `Screenshot 2026-10-13 185938.png` | ALB target reported healthy and repeated requests returned both `nginx-a` and `nginx-b`. | 2026-10-13 18:59 IST |
| `Screenshot 2026-10-13 185945.png` | Continuation of the repeated ALB responses showing both nginx services. | 2026-10-13 18:59 IST |
| `Screenshot 2026-10-13 190016.png` | Upload API returned HTTP 201 and S3 listed the uploaded object. | 2026-10-13 19:00 IST |
| `Screenshot 2026-10-13 190155.png` | Additional repeated ALB responses showing both nginx services. | 2026-10-13 19:01 IST |
| `Screenshot 2026-10-13 190454.png` | Upload API returned HTTP 201 and S3 listed uploaded objects. | 2026-10-13 19:04 IST |

| `ci-github-actions-success.png` | GitHub Actions run showing successful Terraform setup, initialization, formatting, and validation steps. | 2026-10-13 (time not shown) |
