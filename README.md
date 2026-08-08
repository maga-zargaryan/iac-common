# iac-common

Shared AWS network infrastructure, managed with Terraform and deployed via GitHub Actions.

## What this provides

A three-tier VPC in `eu-west-1` spanning two availability zones, plus the shared
Route 53 hosted zone.

| Tier | Subnets | Routing | Intended for |
|---|---|---|---|
| Public | `10.0.1.0/24`, `10.0.2.0/24` | Internet Gateway | Load balancers, NAT Gateway |
| App | `10.0.3.0/24`, `10.0.4.0/24` | NAT Gateway, egress only | Compute |
| Data | `10.0.5.0/24`, `10.0.6.0/24` | Local only, no internet | RDS, EFS |

## Scope

**In scope** — VPC, subnets, route tables, Internet Gateway, NAT Gateway,
RDS subnet group, Route 53 hosted zone, and this repository's own branch
protection rules.

**Out of scope** — security groups. ALB, EC2, EFS and RDS security groups
reference one another and are application-specific, so they belong with the
workload that owns them, not in shared infrastructure.

## Naming convention

Subnets are `<tier>-<az>` — `public-1a`, `app-1a`, `data-1a`.
Shared networking resources inherit the `net` prefix from the module:
`net` (Internet Gateway), `net-eu-west-1a` (NAT Gateway), `net-public`,
`net-private`, `net-db` (route tables).

| Tier | Routing guarantee |
|---|---|
| `public` | Has `0.0.0.0/0` → Internet Gateway |
| `app` | Has `0.0.0.0/0` → NAT Gateway |
| `data` | Local route only |

## Consuming this from another repository

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "tfstate-<ACCOUNT_ID>-eu-west-1"
    key    = "network/terraform.tfstate"
    region = "eu-west-1"
  }
}

locals {
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  app_subnets = data.terraform_remote_state.network.outputs.app_subnet_ids
}
```

### Available outputs

| Output | Description |
|---|---|
| `vpc_id` | VPC ID |
| `vpc_cidr_block` | VPC CIDR |
| `public_subnet_ids` | Tier 1 |
| `app_subnet_ids` | Tier 2 |
| `data_subnet_ids` | Tier 3 |
| `database_subnet_group_name` | RDS subnet group |
| `nat_public_ips` | NAT egress IPs, for allowlisting |
| `availability_zones` | AZs in use |
| `route53_zone_id` | Hosted zone ID |
| `route53_name_servers` | Delegation set |

Outputs are a stable contract. They are not renamed without notice.

## Making changes

Direct pushes to `main` are blocked.

1. Branch from `main`
2. Open a pull request — `plan` runs automatically and posts a summary
3. Review the plan output
4. Merge — `apply` runs automatically

### Branch protection is managed in Terraform

The rules on `main` are defined in `terraform/github.tf`, not set through the
GitHub UI. Changing them in the UI will be reverted by the next apply — edit
the code instead.

| Rule | Setting |
|---|---|
| Pull request required | Yes — direct pushes rejected |
| Required status check | `plan` must pass |
| Branch must be up to date | Yes (`strict = true`) |
| Applies to admins | Yes (`enforce_admins = true`) |
| Approving reviews required | `0` — see note below |
| Force pushes | Blocked |
| Branch deletion | Blocked |

`required_approving_review_count` is `0` because this is a single-maintainer
repository. GitHub does not accept a self-approval when `enforce_admins` is
true, so requiring one review would make merging impossible. Raise it to `1`
when a second maintainer joins.

The `contexts` value must match the GitHub Actions job name exactly. If the
plan job is renamed, update `github.tf` in the same pull request or every
merge will block on a check that never reports.

## Bumping a provider or module version

Version constraints and the lock file must move together.

```bash
cd terraform
# edit the version in providers.tf or vpc.tf
terraform init -upgrade
terraform providers lock -platform=darwin_arm64 -platform=linux_amd64
git add .terraform.lock.hcl providers.tf
```

Commit both in the same pull request. CI runs `init -lockfile=readonly` and
fails if they disagree.

The lock file records provider checksums for both `darwin_arm64` (local
development) and `linux_amd64` (GitHub Actions runners). Both platforms must
be present or CI will fail trying to add the missing hashes to a read-only
lock file.

## CIDR allocation

Reserved to keep future VPCs non-overlapping for peering or Transit Gateway.

| Purpose | CIDR |
|---|---|
| This VPC | `10.0.0.0/16` |
| Reserved | `10.1.0.0/16` – `10.9.0.0/16` |

## Authentication

CI authenticates to AWS via **GitHub OIDC**, assuming
`arn:aws:iam::<ACCOUNT_ID>:role/GitHubActionsRole`. No static AWS credentials
are stored anywhere.

Local access uses IAM Identity Center SSO: `aws sso login --profile iac-admin`

The GitHub API is accessed with a fine-grained PAT held in the `GH_PAT_TOKEN`
repository secret, scoped to this repository with Administration write.
Rotate every 90 days.

The token reaches Terraform as the `TF_VAR_github_token` environment variable,
set on the plan and apply steps. Terraform maps any `TF_VAR_*` variable to the
matching input automatically.

## Resources created outside Terraform

These are prerequisites Terraform cannot manage, created once by hand:

| Resource | Why |
|---|---|
| S3 state bucket | Terraform cannot create its own backend |
| OIDC identity provider | Required before CI can authenticate |
| `GitHubActionsRole` IAM role | Required before CI can authenticate |
| `GH_PAT_TOKEN` secret | Required before the GitHub provider can authenticate |

They survive `terraform destroy`, which is intentional — they are needed to
re-apply.

## The Route 53 hosted zone

The hosted zone pre-existed this configuration and was adopted with an
`import` block, which has since been removed. It carries `prevent_destroy`
because destroying it reissues the name servers and breaks delegation at the
registrar until they are manually re-pointed.

To tear down the VPC while preserving the zone, remove it from state first:

```bash
terraform state rm aws_route53_zone.primary
terraform plan -destroy    # confirm no route53 resources are listed
terraform destroy
```

To re-adopt it afterwards, restore the `import` block in `route53.tf`, apply,
then remove the block again.

## State

S3 at `s3://tfstate-<ACCOUNT_ID>-eu-west-1/network/terraform.tfstate`.
Versioned, encrypted, native S3 lockfile — no DynamoDB.
````