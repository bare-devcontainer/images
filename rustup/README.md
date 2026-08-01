# rustup (rust)

Dev container image for Rust development, with [rustup](https://rustup.rs/) installed,
built on the [debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/rustup:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/rustup:1@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/rust).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `1.29.0-trixie`, `1-trixie`, `trixie`, `1.29.0`, `1` | trixie |
| `1.29.0-bookworm`, `1-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `1.29.0-trixie-<YYYYMMDD>`).
<!-- tags:end -->

The version in these tags is the version of `rustup` itself, not of any Rust toolchain.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [rustup](https://rustup.rs/)

`~/.cargo/bin` is on `PATH`, so the `rustup`/`cargo` shims resolve once a toolchain is
installed.

## Not installed

- **No Rust toolchain.** `rustc`, `cargo`, and the standard library arrive when `rustup`
  installs the toolchain the project asks for, so the version in use is the one the project
  declares rather than the one this image happens to ship.
- **No toolchain components.** `clippy`, `rustfmt`, and `rust-analyzer` ship with the
  toolchain, so they appear only after it is installed — add them with
  `rustup component add clippy rustfmt rust-analyzer`.
- **No cargo subcommands.** `cargo-watch`, `cargo-nextest`, and similar are installed per
  project with `cargo install`.

## Working with toolchains

A project that pins its toolchain in `rust-toolchain.toml` needs no setup: the first `cargo`
or `rustc` invocation installs the pinned toolchain. To install it up front instead of on
first use, run `rustup show` from a `postCreateCommand`. Without a `rust-toolchain.toml`,
install a toolchain explicitly with `rustup toolchain install stable`.

Two directories are worth persisting across container rebuilds as volumes:

- `~/.rustup` — the installed toolchains. Toolchains are re-downloaded on every rebuild
  unless this directory survives.
- `~/.cargo` — the registry and git caches for downloaded crates.

## Supply chain

`rustup` is downloaded directly from the official [rustup release archive](https://static.rust-lang.org/rustup/).
rustup publishes no signature for `rustup-init`, so it is verified against a SHA-256 checksum
file committed to this repository (`rustup/rustup-init-<arch>.sha256`) rather than one fetched
from the same server as the binary. The committed checksum files are kept in sync with the
pinned `RUSTUP_VERSION` by an automated workflow and reviewed like any other change, so later
tampering with the download channel cannot affect builds.

Note that this covers `rustup` itself. Toolchains it installs at runtime are downloaded from
static.rust-lang.org under rustup's own signature verification, outside this image's build
pipeline.
