# terraform-cloudflare-zone

This Terraform project provisions a Cloudflare zone (domain) using the official Cloudflare Terraform provider. It creates a managed zone inside a Cloudflare account and exposes the `zone_id`, `name_servers`, and `status` as outputs so downstream modules (e.g. `terraform-cloudflare-dns-record`) can consume them.

## Features

- Creates and manages a Cloudflare Zone (domain) via Infrastructure as Code
- Supports `full` and `partial` zone types (partial = CNAME setup)
- Exposes `zone_id`, `name_servers`, and `status` for downstream use
- Sensitive values (API token) are marked sensitive
- Clean, minimal configuration

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.0`
- A [Cloudflare account](https://dash.cloudflare.com/sign-up)
- The Cloudflare **Account ID** of the target account
- A Cloudflare API Token with **Zone:Zone:Edit** (and **Zone:DNS:Edit** if you plan to add records in the same run) permissions

### How to get your Cloudflare Account ID

1. Log in to the [Cloudflare dashboard](https://dash.cloudflare.com/).
2. Open **Workers and Pages** (or any dashboard section) — the Account ID appears in the URL:
   `https://dash.cloudflare.com/<ACCOUNT_ID>/<zone>/...`.
3. Copy the `<ACCOUNT_ID>` value.

> If you belong to multiple accounts, confirm you are using the correct one.

### How to get your Cloudflare API Token

1. Log in to the [Cloudflare dashboard](https://dash.cloudflare.com/).
2. Go to **My Profile** → **API Tokens**, or open [this direct link](https://dash.cloudflare.com/profile/api-tokens).
3. Click **Create Token**.
4. Under **Custom token**, click **Get started**.
5. Give the token a descriptive name (e.g., `terraform-zone`).
6. Under **Permissions**, add:
   - `Zone` → `Zone` → `Edit`
   - `Zone` → `DNS` → `Edit` (only if you plan to manage records too)
7. Under **Zone Resources**, select `All accounts` or scope to the relevant account.
8. (Optional) Set **TTL** and **IP Address Filtering** as needed.
9. Click **Continue to summary** → **Create Token**.
10. Copy the generated token immediately and store it securely — it won't be shown again.

> Use a scoped API token rather than your Global API Key for least-privilege access.

## Usage

### 1. Clone and configure

```bash
git clone https://github.com/marcuwynu23/terraform-cloudflare-zone.git
cd terraform-cloudflare-zone
cp terraform.tfvars.example terraform.tfvars
```

### 2. Set your values in `terraform.tfvars`

```hcl
cloudflare_api_token = "your-api-token-here"
account_id           = "your-cloudflare-account-id"
zone_name            = "example.com"
type                 = "full"
jump_start           = false
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Preview changes

```bash
terraform plan
```

### 5. Apply

```bash
terraform apply
```

### 6. Destroy (when no longer needed)

```bash
terraform destroy
```

## Variables

| Name                   | Description                                              | Type     | Default  | Required |
| ---------------------- | -------------------------------------------------------- | -------- | -------- | :------: |
| `cloudflare_api_token` | Cloudflare API Token with Zone:Zone:Edit permission      | `string` | n/a      |   yes    |
| `account_id`           | Cloudflare Account ID where the zone will be created     | `string` | n/a      |   yes    |
| `zone_name`            | The domain name of the zone (e.g., `example.com`)        | `string` | n/a      |   yes    |
| `type`                 | Zone type: `full`, `partial`, or `secondary`           | `string` | `full`   |    no    |

## Outputs

| Name          | Description                                                       |
| ------------- | ----------------------------------------------------------------- |
| `zone_id`     | The Cloudflare Zone ID (pass this to DNS-record modules)         |
| `zone_name`   | The zone name (domain)                                          |
| `name_servers`| Cloudflare nameservers assigned to the zone (for your registrar)|
| `status`      | The zone status (e.g., `active`, `pending`)                     |
| `account_id`  | The Cloudflare Account ID the zone belongs to                   |

## Usage as a Module

Reference this repository as a Terraform module in your own configurations:

> **Option 1**: Terraform Registry (recommended)
> ```hcl
> module "cloudflare-zone" {
>   source  = "marcuwynu23/zone/cloudflare"
>   version = "1.0.0"
>
>   cloudflare_api_token = var.cloudflare_api_token
>   account_id           = var.account_id
>   zone_name            = "example.com"
> }
> ```
>
> **Option 2**: GitHub source
> ```hcl
> module "cloudflare-zone" {
>   source = "github.com/marcuwynu23/terraform-cloudflare-zone?ref=main"
>
>   cloudflare_api_token = var.cloudflare_api_token
>   account_id           = var.account_id
>   zone_name            = "example.com"
> }
> ```

Then use the outputs in your configuration:

```hcl
output "zone_id" {
  value = module.cloudflare_zone.zone_id
}

output "name_servers" {
  value = module.cloudflare_zone.name_servers
}
```

All variables and outputs documented above are available when using this as a module.

## Examples

### Full zone (default)

```hcl
account_id = "0123457890abcdef0123457890abcdef"
zone_name  = "example.com"
type       = "full"
```

### Partial zone (CNAME setup)

```hcl
account_id = "0123457890abcdef0123457890abcdef"
zone_name  = "example.com"
type       = "partial"
```

## Resources Created

- `cloudflare_zone.this` – Cloudflare Zone (domain)

## Notes

- Creating a `cloudflare_zone` registers the domain in your Cloudflare account. If the domain's nameservers are not yet pointing at Cloudflare, the zone will enter a `pending` verification state.
- The output `name_servers` are the nameservers Cloudflare assigns to the zone — set these at your domain registrar to activate proxying.

## Security Notes

- `terraform.tfvars` and `*.tfstate` files are gitignored — never commit secrets
- The API token variable is marked `sensitive` to prevent accidental log exposure
- Use a scoped API token rather than a Global API Key

## References

- [Cloudflare Zones](https://developers.cloudflare.com/cloudflare-for-platforms/zone-management/)
- [Cloudflare Terraform provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [cloudflare_zone resource](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/zone)

## CI/CD Setup (GitHub Actions)

### Prerequisites
1. **Create a GCS bucket** for Terraform remote state:
    ```bash
    gcloud storage buckets create gs://your-terraform-state-bucket \
      --location=us-central1 \
      --uniform-bucket-level-access
    ```

2. **Create a service account** with necessary permissions and generate a JSON key:
    - GCP Console → IAM & Admin → Service Accounts → Create Service Account
    - Grant the required roles for this module
    - Keys → Add Key → Create New Key → JSON
    - Copy the entire JSON file contents

3. **Add GitHub secrets**:

    | Secret Name | Value |
    |---|---|
    | `GCP_SA_KEY` | Full JSON key from step 2 |
    | `TF_BUCKET_NAME` | Your GCS bucket name |
    | `TF_BUCKET_PREFIX` | Bucket prefix/path (e.g., `cloudflare-zone`) |
    | `CLOUDFLARE_API_TOKEN` | Your Cloudflare API token |

4. **Run the workflow**:
    - **Apply**: Go to Actions → **CD - Cloudflare Zone (Apply)** → fill in all inputs
    - **Destroy**: Go to Actions → **CD - Cloudflare Zone (Destroy)** → fill in essential inputs

> Alternatively, create a `backend.tfvars` from `backend.tfvars.example` and run `terraform init -backend-config="backend.tfvars"` for local use.

## Remote State (GCS Backend)

This module uses Google Cloud Storage (GCS) as the Terraform backend for remote state management:

```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "cloudflare-zone"
  }
}
```

Create a `backend.tfvars` file based on `backend.tfvars.example` and initialize:

```bash
terraform init -backend-config="backend.tfvars"
```
