# rust

Dev container image with Rust installed via `rustup`, built on the [debian](../debian) base image.

`rustup` is installed from the Debian package repository. Rust toolchains are managed by `rustup` and stored in `~/.cargo`.
Note that Rust toolchain is not installed by default since most projects will specify a toolchain in their `rust-toolchain.toml` file. 

## Image

```
ghcr.io/bare-devcontainer/rust:<tag>
```

## Tags

| Tag | Debian version |
|-----|---------------|
| `trixie` | Debian 13 (trixie) |

Tags are also published with a date suffix (e.g., `trixie-20260623`) on each build.

## Installed software

Everything from the [debian](../debian) base image, plus:

- **rustup** (Rust toolchain installer)
