# golang

Dev container image with Go installed, built on the [debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/golang:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/golang:1.26@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/golang).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `1.27.0-trixie`, `1.27-trixie`, `1-trixie`, `trixie`, `1.27.0`, `1.27`, `1` | trixie |
| `1.27.0-bookworm`, `1.27-bookworm`, `1-bookworm`, `bookworm` | bookworm |
| `1.26.7-trixie`, `1.26-trixie`, `1.26.7`, `1.26` | trixie |
| `1.26.7-bookworm`, `1.26-bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `1.27.0-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Go toolchain](https://go.dev/)
- [gopls](https://go.dev/gopls/)
- `pkg-config`, so cgo works out of the box (plus `binutils-gold` on arm64, which Go's
  external linker needs there)

`GOPATH` is `/home/dev/go`, and both `/usr/local/go/bin` and `${GOPATH}/bin` are on `PATH`.

## Not installed

- **No linters or debuggers.** `golangci-lint`, `staticcheck`, and `delve` are absent; install
  the versions the project pins with `go install`.
- **No cross-compilation sysroots.** Pure-Go cross builds work as usual, but cgo builds
  targeting another platform need their own toolchain.

Unlike the version-manager images, the Go toolchain here is fixed by the image tag. A project
that raises its `go` directive past the installed version will fall back to Go's own toolchain
download unless `GOTOOLCHAIN=local` is set; pick the matching image tag instead.

## Supply chain

The Go toolchain is downloaded directly from [go.dev](https://go.dev/dl/) and verified against
Google's GPG signature before installation. The signing key
(`golang/google-linux-signing-key.asc`) is committed to this repository, so signatures are
checked against a key reviewed here rather than one fetched at build time. `gopls` is built
from source in a throwaway builder stage at a pinned version, and only the resulting binary is
copied into the final image.
