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
| <!-- renovate: datasource=golang-version depName=golang versioning=semver -->`1.26.5-trixie`, `1.26-trixie`, `1-trixie`, <!-- renovate: datasource=golang-version depName=golang versioning=semver -->`1.26.5`, `1.26`, `1`, `trixie` | 1.26.x | trixie |
| <!-- renovate: datasource=golang-version depName=golang versioning=semver -->`1.26.5-bookworm`, `1.26-bookworm`, `1-bookworm`, `bookworm` | 1.26.x | bookworm |
| <!-- renovate: datasource=golang-version depName=golang versioning=semver -->`1.25.12-trixie`, `1.25-trixie`, <!-- renovate: datasource=golang-version depName=golang versioning=semver -->`1.25.12`, `1.25` | 1.25.x | trixie |
| <!-- renovate: datasource=golang-version depName=golang versioning=semver -->`1.25.12-bookworm`, `1.25-bookworm` | 1.25.x | bookworm |

Tags are also published with a date suffix (e.g., `<tag>-20260623`) on each build.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Go toolchain](https://go.dev/)
- [gopls](https://go.dev/gopls/)
