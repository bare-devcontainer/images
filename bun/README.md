# bun

Dev container image for JavaScript/TypeScript development, with the [Bun](https://bun.com/)
runtime installed, built on the [debian](../debian) base image.

`bun` is downloaded directly from [GitHub Releases](https://github.com/oven-sh/bun/releases).
Its checksum is verified against `SHASUMS256.txt`, whose GPG signature (`SHASUMS256.txt.asc`) is
verified against Bun's release signing key before installation.

## Image

```
ghcr.io/bare-devcontainer/bun:<tag>
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/bun).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `1.3.14-trixie`, `1-trixie`, `1.3.14`, `1`, `trixie` | trixie |
| `1.3.14-bookworm`, `1-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `1.3.14-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Bun](https://bun.com/) (`bun`, `bunx`)
