# node

Dev container image with Node.js installed, built on the [debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/node:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/node:26@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/node).
It provides the recommended configuration for this image, including security hardening.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `26.8.1-trixie`, `26-trixie`, `trixie`, `26.8.1`, `26` | trixie |
| `26.8.1-bookworm`, `26-bookworm`, `bookworm` | bookworm |
| `24.20.0-trixie`, `24-trixie`, `24.20.0`, `24` | trixie |
| `24.20.0-bookworm`, `24-bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `26.8.1-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Node.js](https://nodejs.org/)
- [Corepack](https://nodejs.org/api/corepack.html)

## Not installed

- **No `npm` or `npx`.** Both are removed from the image, so the package manager comes from
  the project's `packageManager` field through Corepack rather than from the image.
- **No enabled package manager.** Corepack is installed but not enabled by default. Run
  `corepack enable` as root — for example in a `Dockerfile` layered on this image — to
  activate the `yarn`/`pnpm` shims.
- **No global JavaScript tooling.** Linters, formatters, and test runners are left to the
  project's own dependencies.

## Supply chain

The Node.js binary is downloaded from [nodejs.org](https://nodejs.org/dist/), and its checksum
is verified against `SHASUMS256.txt.asc`, signed by the Node.js Release Team. The keyring
(`node/node-keyring.kbx`) is committed to this repository, so signatures are checked against
keys reviewed here rather than keys fetched at build time.
