# golang

Dev container image with Go installed, built on the [debian](../debian) base image.

The Go toolchain is downloaded directly from [go.dev](https://go.dev/dl/) and verified against Google's GPG signature before installation.

## Image

```
ghcr.io/bare-devcontainer/golang:<tag>
```

## Tags

| Tag | Go version | Debian version |
|-----|-----------|---------------|
| `1.26.4-trixie`, `1.26-trixie`, `1-trixie`, `1.26.4`, `1.26`, `1` | 1.26.x | trixie |
| `1.26.4-bookworm`, `1.26-bookworm`, `1-bookworm` | 1.26.x | bookworm |
| `1.25.11-trixie`, `1.25-trixie`, `1.25.11`, `1.25` | 1.25.x | trixie |
| `1.25.11-bookworm`, `1.25-bookworm` | 1.25.x | bookworm |

Tags are also published with a date suffix (e.g., `1.26.4-trixie-20260623`) on each build.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Go toolchain](https://go.dev/)
- [gopls](https://go.dev/gopls/)
