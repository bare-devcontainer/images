# rust

Dev container image with Rust installed via `rustup`, built on the [debian](../debian) base image.

`rustup` is downloaded directly from the official [rustup release archive](https://static.rust-lang.org/rustup/). rustup publishes no signature for `rustup-init`, so it is verified against a SHA-256 checksum file committed to this repository (`rust/rustup-init-<arch>.sha256`) rather than one fetched from the same server as the binary. The committed checksum files are kept in sync with the pinned `RUSTUP_VERSION` by an automated workflow and reviewed like any other change, so later tampering with the download channel cannot affect builds. Rust toolchains are managed by `rustup` and stored in `~/.cargo`.

## Image

```
ghcr.io/bare-devcontainer/rust:<tag>
```

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `1.29.0-trixie`, `1-trixie`, `trixie`, `1.29.0`, `1` | trixie |
| `1.29.0-bookworm`, `1-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `1.29.0-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [rustup](https://rustup.rs/)

Note that Rust toolchain is not installed by default since most projects will specify a toolchain in their `rust-toolchain.toml` file. 
