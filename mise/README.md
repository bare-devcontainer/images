# mise

Dev container image with [mise](https://mise.jdx.dev/) installed, built on the [debian](../debian) base image.

mise is a polyglot runtime manager that can install and manage multiple language toolchains (Node.js, Python, Ruby, Go, etc.) per project.

## Image

```
ghcr.io/bare-devcontainer/mise:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/mise:trixie@sha256:<digest>"
}
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
| `2026.8.10-trixie`, `2026.8.10`, `trixie` | trixie |

Tags are also published with a date suffix on each build (e.g., `2026.8.10-trixie-<YYYYMMDD>`).
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

The shims directory `~/.local/share/mise/shims` is on `PATH`, so tools resolve as soon as mise
installs them.

## Not installed

- **No language runtime.** Nothing is installed until the project asks for it — that is the
  point of this image. mise resolves the versions declared in `mise.toml` (and the idiomatic
  per-language files such as `.node-version` or `.python-version`).
- **No development headers beyond libc.** The base image's `build-essential` covers the
  compiler and linker, so backends that download prebuilt binaries and simple source builds
  both work as-is. A backend that builds a language runtime from source additionally needs the
  `-dev` packages of the libraries it links against, such as `libssl-dev` or `zlib1g-dev`.

## Working with tools

`mise install` installs everything the project declares; `mise exec <tool>@<version> -- <cmd>`
runs a one-off without declaring anything. To install the project's tools when the container is
created rather than on first use, run `mise install` from a `postCreateCommand`.

Two directories are worth persisting across container rebuilds as volumes:

- `~/.local/share/mise` — the installed tools. Everything is re-downloaded on every rebuild
  unless this directory survives.
- `~/.cache/mise` — the download cache.

## Supply chain

The mise binary is downloaded from [GitHub Releases](https://github.com/jdx/mise/releases). Its
checksum is verified against `SHASUMS256.txt`, whose minisign signature is verified against
mise's public key (`mise/mise-minisign.pub`) before installation. The key is committed to this
repository, so signatures are checked against a key reviewed here rather than one fetched at
build time.

Note that this covers the mise binary only. Tools that mise installs at runtime are fetched
from their own upstreams under mise's own verification, outside this image's build pipeline.
