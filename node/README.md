# node

Dev container image with Node.js installed, built on the [debian](../debian) base image.

The Node.js binary is downloaded from nodejs.org and verified against a GPG signature from the Node.js Release Team before installation.

## Image

```
ghcr.io/bare-devcontainer/node:<tag>
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/node).
It provides the recommended configuration for this image, including security hardening.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `26.5.0-trixie`, `26-trixie`, `trixie`, `26.5.0`, `26` | trixie |
| `26.5.0-bookworm`, `26-bookworm`, `bookworm` | bookworm |
| `24.18.0-trixie`, `24-trixie`, `24.18.0`, `24` | trixie |
| `24.18.0-bookworm`, `24-bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `26.5.0-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Node.js](https://nodejs.org/)
- [Corepack](https://nodejs.org/api/corepack.html)

npm and npx are removed from the image; use Corepack-managed `yarn`/`pnpm` instead. Corepack is installed but not enabled by default. Run `corepack enable` (as root) to activate the `yarn`/`pnpm` shims for a project's `packageManager` field.
