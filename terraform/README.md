# terraform

Dev container image for infrastructure-as-code development, with the [Terraform](https://www.terraform.io/)
CLI and [terraform-ls](https://github.com/hashicorp/terraform-ls) language server installed, built on the
[debian](../debian) base image.

`terraform` and `terraform-ls` are downloaded directly from
[HashiCorp's release server](https://releases.hashicorp.com/). Each binary's checksum is verified against
its `SHA256SUMS`, whose GPG signature (`SHA256SUMS.sig`) is verified against HashiCorp's release signing
key before installation.

## Image

```
ghcr.io/bare-devcontainer/terraform:<tag>
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
