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

## Tags

| Tag | Terraform version | Debian version |
|-----|-------------------|-----------------|
| <!-- renovate: datasource=github-releases depName=hashicorp/terraform versioning=semver extractVersion=^v(?<version>.+) -->`1.15.8-trixie`, `1-trixie`, <!-- renovate: datasource=github-releases depName=hashicorp/terraform versioning=semver extractVersion=^v(?<version>.+) -->`1.15.8`, `1`, `trixie` | 1.x | trixie |
| <!-- renovate: datasource=github-releases depName=hashicorp/terraform versioning=semver extractVersion=^v(?<version>.+) -->`1.15.8-bookworm`, `1-bookworm`, `bookworm` | 1.x | bookworm |

Tags are also published with a date suffix (e.g., `<tag>-20260623`) on each build.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Terraform](https://www.terraform.io/) (`terraform`)
- [terraform-ls](https://github.com/hashicorp/terraform-ls) (`terraform-ls`)
