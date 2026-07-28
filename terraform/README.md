# terraform

Dev container image for infrastructure-as-code development, with the [Terraform](https://www.terraform.io/)
CLI and [terraform-ls](https://github.com/hashicorp/terraform-ls) language server installed, built on the
[debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/terraform:<tag>
```

```json
{
  "image": "ghcr.io/bare-devcontainer/terraform:1@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/terraform).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `1.15.8-trixie`, `1-trixie`, `1.15.8`, `1`, `trixie` | trixie |
| `1.15.8-bookworm`, `1-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `1.15.8-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Terraform](https://www.terraform.io/) (`terraform`)
- [terraform-ls](https://github.com/hashicorp/terraform-ls) (`terraform-ls`)

`TF_PLUGIN_CACHE_DIR` points at `~/.terraform.d/plugin-cache`, so providers are downloaded once
and shared across working directories. Persisting that directory as a volume keeps them across
container rebuilds.

## Not installed

- **No cloud provider CLIs.** `aws`, `gcloud`, and `az` are absent. Add the one the project
  needs through a Dev Container Feature or your own `Dockerfile`.
- **No credential helpers or authentication.** Nothing in the image logs in to a cloud
  account; supply credentials the way you would outside a container.
- **No adjacent Terraform tooling.** `terragrunt`, `tflint`, `tfsec`, and similar are left to
  the project.

## Supply chain

`terraform` and `terraform-ls` are downloaded directly from
[HashiCorp's release server](https://releases.hashicorp.com/). Each binary's checksum is verified against
its `SHA256SUMS`, whose GPG signature (`SHA256SUMS.sig`) is verified against HashiCorp's release signing
key before installation. The key (`terraform/hashicorp-signing-key.asc`) is committed to this
repository, so signatures are checked against a key reviewed here rather than one fetched at
build time.

Note that this covers the CLI. Providers that `terraform init` downloads at runtime come from
the Terraform Registry under Terraform's own checksum and signature verification, outside this
image's build pipeline.
