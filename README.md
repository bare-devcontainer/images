# Bare Dev Container Images

[![Lint](https://github.com/bare-devcontainer/images/actions/workflows/lint.yml/badge.svg)](https://github.com/bare-devcontainer/images/actions/workflows/lint.yml)

Minimal, secure, and bloat-free Dev Container base images for various technology stacks, published to GitHub Container Registry.

## Goals

- **Dev Container ready** — Each image comes with standard Dev Container configuration pre-applied, so it works out of the box.
- **Minimal attack surface** — Each image includes only the packages and configuration required for its target stack. Keeping installed software to a minimum helps reduce the potential vulnerability surface of each development environment.
- **Minimal trusted upstreams** — Software is sourced only from the official Debian package archive, Docker Official Images, and the official distribution channels for each language runtime or package manager. Keeping the set of trusted suppliers small helps reduce supply-chain exposure.
- **Secure build pipeline** — All dependencies are pinned to specific versions and content digests. Published images include SLSA provenance attestations, making the build process verifiable.
- **Regular base updates** — Debian base images are updated regularly with Renovate so upstream security patches can be incorporated promptly.

Dev Container base images are available from Microsoft ([link](https://github.com/devcontainers/images)), but they are often larger than necessary and include many packages that may not be needed for a given development environment. These images are intended to provide a more minimal alternative.

## Images

| Image | Registry | Description |
|-------|----------|-------------|
| [debian](debian/README.md) | `ghcr.io/bare-devcontainer/debian` | Debian base image (trixie / bookworm) |
| [golang](golang/README.md) | `ghcr.io/bare-devcontainer/golang` | Go toolchain on Debian |
| [rust](rust/README.md) | `ghcr.io/bare-devcontainer/rust` | Rust (via rustup) on Debian |
| [zig](zig/README.md) | `ghcr.io/bare-devcontainer/zig` | Zig compiler on Debian |
| [mise](mise/README.md) | `ghcr.io/bare-devcontainer/mise` | mise runtime manager on Debian |

## License

[MIT](LICENSE)
