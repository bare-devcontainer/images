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

## Tags

| Tag | Bun version | Debian version |
|-----|------------|---------------|
| `1.3.14-trixie`, `1.3.14`, `trixie` | 1.3.14 | trixie |
| `1.3.14-bookworm`, `bookworm` | 1.3.14 | bookworm |

Tags are also published with a date suffix (e.g., `1.3.14-trixie-20260704`) on each build.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Bun](https://bun.com/) (`bun`, `bunx`)
