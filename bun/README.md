# bun

Dev container image for JavaScript/TypeScript development, with the [Bun](https://bun.com/)
runtime installed, built on the [debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/bun:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/bun:1@sha256:<digest>"
}
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
| `1.4.0-trixie`, `1-trixie`, `1.4.0`, `1`, `trixie` | trixie |
| `1.4.0-bookworm`, `1-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `1.4.0-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Bun](https://bun.com/) (`bun`, `bunx`)

## Not installed

- **No Node.js, `npm`, or `npx`.** Bun runs the scripts and installs the packages. A project
  that also needs the Node.js runtime is better served by the [node](../node) image.
- **No global JavaScript tooling.** Linters, formatters, and test runners are left to the
  project's own dependencies; Bun's built-in test runner and bundler cover part of that ground.

## Supply chain

`bun` is downloaded directly from [GitHub Releases](https://github.com/oven-sh/bun/releases).
Its checksum is verified against `SHASUMS256.txt`, whose GPG signature (`SHASUMS256.txt.asc`) is
verified against Bun's release signing key before installation. The key
(`bun/bun-signing-key.asc`) is committed to this repository, so signatures are checked against
a key reviewed here rather than one fetched at build time.
