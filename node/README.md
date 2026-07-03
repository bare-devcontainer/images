# node

Dev container image with Node.js installed, built on the [debian](../debian) base image.

The Node.js binary is downloaded from nodejs.org and verified against a GPG signature from the Node.js Release Team before installation.

## Image

```
ghcr.io/bare-devcontainer/node:<tag>
```

## Tags

| Tag | Node.js version | Debian version |
|-----|-----------------|---------------|
| `26.4.0-trixie`, `26-trixie`, `26.4.0`, `26` | 26.x (Current) | trixie |
| `26.4.0-bookworm`, `26-bookworm` | 26.x (Current) | bookworm |
| `24.18.0-trixie`, `24-trixie`, `24.18.0`, `24` | 24.x (LTS) | trixie |
| `24.18.0-bookworm`, `24-bookworm` | 24.x (LTS) | bookworm |

Tags are also published with a date suffix (e.g., `24.18.0-trixie-20260623`) on each build.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Node.js](https://nodejs.org/)
- [Corepack](https://nodejs.org/api/corepack.html)

npm and npx are removed from the image; use Corepack-managed `yarn`/`pnpm` instead. Corepack is installed but not enabled by default. Run `corepack enable` (as root) to activate the `yarn`/`pnpm` shims for a project's `packageManager` field.
