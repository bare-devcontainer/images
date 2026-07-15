# mise

Dev container image with [mise](https://mise.jdx.dev/) installed, built on the [debian](../debian) base image.

mise is a polyglot runtime manager that can install and manage multiple language toolchains (Node.js, Python, Ruby, Go, etc.) per project.

The mise binary is downloaded from GitHub Releases and verified with a minisign signature before installation.

## Image

```
ghcr.io/bare-devcontainer/mise:<tag>
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/mise).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `2026.7.6-trixie`, `2026.7.6`, `trixie` | trixie |

Tags are also published with a date suffix on each build (e.g., `2026.7.6-trixie-<YYYYMMDD>`).
<!-- tags:end -->

> [!NOTE]
> The `bookworm` variant has been discontinued. mise 2026.7.0 and later require
> a newer glibc than bookworm provides, and mise uses calendar versioning, so
> no future mise release will ever be compatible with bookworm again. Rather
> than publishing a permanently frozen mise that no longer receives security
> fixes, only the trixie variant is maintained. Previously published bookworm
> tags remain available on GHCR but will not be updated.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [mise](https://mise.jdx.dev/)
