# rust

Dev container image with Rust installed via `rustup`, built on the [debian](../debian) base image.

`rustup` is downloaded directly from the official [rustup release archive](https://static.rust-lang.org/rustup/) and verified against its published SHA-256 checksum. Rust toolchains are managed by `rustup` and stored in `~/.cargo`.

## Image

```
ghcr.io/bare-devcontainer/rust:<tag>
```

## Tags

| Tag | rustup version | Debian version |
|-----|----------------|---------------|
| <!-- renovate: datasource=github-releases depName=rust-lang/rustup versioning=semver -->`1.29.0-trixie`, `1-trixie`, <!-- renovate: datasource=github-releases depName=rust-lang/rustup versioning=semver -->`1.29.0`, `1`, `trixie` | 1.x | trixie |
| <!-- renovate: datasource=github-releases depName=rust-lang/rustup versioning=semver -->`1.29.0-bookworm`, `1-bookworm`, `bookworm` | 1.x | bookworm |

Tags are also published with a date suffix (e.g., `<tag>-20260623`) on each build.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [rustup](https://rustup.rs/)

Note that Rust toolchain is not installed by default since most projects will specify a toolchain in their `rust-toolchain.toml` file. 
