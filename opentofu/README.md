# opentofu

Dev container image for infrastructure-as-code development, with the [OpenTofu](https://opentofu.org/)
CLI and [tofu-ls](https://github.com/opentofu/tofu-ls) language server installed, built on the
[debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/opentofu:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/opentofu:1@sha256:<digest>"
}
```

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `1.12.5-trixie`, `1-trixie`, `1.12.5`, `1`, `trixie` | trixie |
| `1.12.5-bookworm`, `1-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `1.12.5-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [OpenTofu](https://opentofu.org/) (`tofu`)
- [tofu-ls](https://github.com/opentofu/tofu-ls) (`tofu-ls`)

`TF_PLUGIN_CACHE_DIR` points at `~/.terraform.d/plugin-cache`, so providers are downloaded once
and shared across working directories. Persisting that directory as a volume keeps them across
container rebuilds.

## Not installed

- **No cloud provider CLIs.** `aws`, `gcloud`, and `az` are absent. Add the one the project
  needs through a Dev Container Feature or your own `Dockerfile`.
- **No credential helpers or authentication.** Nothing in the image logs in to a cloud
  account; supply credentials the way you would outside a container.
- **No adjacent OpenTofu tooling.** `terragrunt`, `tflint`, `tfsec`, and similar are left to
  the project.

## Supply chain

`tofu` is downloaded directly from the
[OpenTofu release page](https://github.com/opentofu/opentofu/releases). Its checksum is verified against
its `SHA256SUMS`, whose GPG signature (`SHA256SUMS.gpgsig`) is verified against OpenTofu's release signing
key before installation. The key (`opentofu/opentofu-signing-key.asc`) is committed to this
repository, so signatures are checked against a key reviewed here rather than one fetched at
build time.

`tofu-ls` publishes no signature, so its `checksums.txt` (`opentofu/tofu-ls-checksums.txt`) is
committed to this repository instead and refreshed whenever the pinned version changes. The
archive is verified against that reviewed copy rather than the one served from its own release.

Note that this covers the CLI. Providers that `tofu init` downloads at runtime come from the
OpenTofu Registry under OpenTofu's own checksum and signature verification, outside this
image's build pipeline.
