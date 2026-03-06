# Code Review Report

Date: 2026-03-06

## Scope

Reviewed the Terraform-based AWS migration lab with a focus on:

- security vulnerabilities
- Terraform / IaC best practices
- operational risks that could affect secure deployments

Primary files reviewed:

- `terraform/alb.tf`
- `terraform/ec2_ssm.tf`
- `terraform/security_groups.tf`
- `terraform/subnets_routes_nat.tf`
- `terraform/providers.tf`
- `terraform/variables.tf`
- `terraform/user_data.sh`
- `.gitignore`

## Executive Summary

The project demonstrates several good baseline practices already:

- EC2 runs in a private subnet with no public IP
- access is intended through an ALB
- administration uses SSM instead of SSH
- Terraform state and tfvars patterns are ignored in Git

Main concerns are around transport security, instance hardening, Terraform reproducibility, and production-readiness controls.

## Findings

### 1. Internet-facing ALB serves only HTTP

- **Severity:** High
- **File:** `terraform/alb.tf`
- **Issue:** The ALB listener is configured only on port `80` using `HTTP`.
- **Risk:** Traffic between clients and the ALB is unencrypted, which exposes requests to interception or tampering on untrusted networks.
- **Recommendation:**
  - Add an HTTPS listener on port `443`
  - Attach an ACM certificate
  - Redirect `HTTP` to `HTTPS`
  - Consider enabling HSTS at the application or edge layer

### 2. IMDSv2 is not enforced on the EC2 instance

- **Severity:** Medium
- **File:** `terraform/ec2_ssm.tf`
- **Issue:** The `aws_instance` resource does not define `metadata_options`.
- **Risk:** If IMDSv1 remains allowed, software running on the instance may be more exposed to SSRF-style credential theft paths.
- **Recommendation:** Require IMDSv2 explicitly:
  - `http_tokens = "required"`
  - optionally reduce metadata exposure further if not needed

### 3. EBS encryption is not explicitly required

- **Severity:** Medium
- **File:** `terraform/ec2_ssm.tf`
- **Issue:** No `root_block_device` configuration explicitly enforces encryption.
- **Risk:** Encryption may depend on account defaults instead of being guaranteed by code.
- **Recommendation:** Explicitly set root volume encryption and, if appropriate, define a KMS key policy for controlled access.

### 4. Terraform lockfile is being ignored

- **Severity:** Medium
- **File:** `.gitignore`
- **Issue:** `.terraform.lock.hcl` is ignored.
- **Risk:** Provider version resolution can drift across machines and over time, reducing reproducibility and increasing supply-chain uncertainty.
- **Recommendation:**
  - Stop ignoring `.terraform.lock.hcl`
  - Generate and commit the lockfile
  - Keep provider selections reviewed and intentional

### 5. Provider version constraints are too broad

- **Severity:** Low
- **File:** `terraform/providers.tf`
- **Issue:** AWS provider is pinned only as `>= 5.0`.
- **Risk:** Future provider releases may introduce behavior changes or breaking changes during routine init/apply operations.
- **Recommendation:** Use a narrower compatible constraint such as a `~>` range aligned to the tested major/minor version.

### 6. Local operator-specific AWS profile is committed as a default

- **Severity:** Low
- **File:** `terraform/variables.tf`
- **Issue:** `aws_profile` defaults to `Test_user`.
- **Risk:** This reduces portability and can cause accidental use of the wrong AWS account on another machine where that profile name exists.
- **Recommendation:** Remove the default and supply the profile through environment variables, CLI flags, or uncommitted local configuration.

### 7. No explicit remote backend for Terraform state

- **Severity:** Medium
- **Files:** `terraform/providers.tf`, repo structure / README
- **Issue:** No remote backend is configured.
- **Risk:** Local state is easier to lose, harder to share safely, and lacks centralized locking and encryption controls.
- **Recommendation:** Use a remote backend suitable for team workflows, such as S3 with encryption and state locking.

### 8. ALB and instance security groups allow unrestricted egress

- **Severity:** Low
- **File:** `terraform/security_groups.tf`
- **Issue:** Both security groups allow all outbound traffic.
- **Risk:** Broad egress increases blast radius if the instance or a dependent component is compromised.
- **Recommendation:** Restrict egress where practical, especially for production environments, or document why unrestricted egress is acceptable for this lab.

### 9. Public entry point lacks visible protective controls such as WAF and access logs

- **Severity:** Low
- **File:** `terraform/alb.tf`
- **Issue:** The internet-facing ALB does not appear to enable access logging or integrate with a WAF.
- **Risk:** Reduced visibility into attacks and fewer options for filtering abusive traffic.
- **Recommendation:** For anything beyond a lab, enable ALB access logs and consider AWS WAF for baseline protection.

### 10. AMI comment does not match the selected AMI family

- **Severity:** Low
- **File:** `terraform/ec2_ssm.tf`
- **Issue:** The comment says `Amazon Linux 2023 AMI`, but the filter selects `amzn2-ami-*`.
- **Risk:** Mismatched documentation can cause incorrect assumptions during maintenance and patching decisions.
- **Recommendation:** Either update the comment or migrate the instance definition to Amazon Linux 2023 if that is the intended baseline.

## Positive Practices Observed

- Instance is placed in a private subnet
- `associate_public_ip_address = false`
- SSH is avoided in favor of SSM Session Manager
- Instance ingress is limited to the ALB security group
- Terraform state and tfvars files are excluded from Git

## Suggested Priority Order

1. Add HTTPS/TLS to the ALB
2. Enforce IMDSv2
3. Explicitly require EBS encryption
4. Commit the Terraform lockfile and tighten provider constraints
5. Remove the committed default AWS profile
6. Add a remote backend and improve logging / visibility controls

## Validation Notes

- Static review completed from repository contents
- IDE diagnostics reported no syntax issues in the reviewed Terraform files
- `terraform fmt -check -recursive` could not be executed because the `terraform` CLI is not installed in the current environment