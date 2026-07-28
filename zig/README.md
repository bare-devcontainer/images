# zig

Dev container image with the Zig compiler installed, built on the [debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/zig:<tag>
```

```json
{
  "image": "ghcr.io/bare-devcontainer/zig:0.16@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/zig).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `0.16.0-trixie`, `0.16-trixie`, `0-trixie`, `trixie`, `0.16.0`, `0.16`, `0` | trixie |
| `0.16.0-bookworm`, `0.16-bookworm`, `bookworm` | bookworm |
| `0.15.2-trixie`, `0.15-trixie`, `0.15.2`, `0.15` | trixie |
| `0.15.2-bookworm`, `0.15-bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `0.16.0-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Zig bundle](https://ziglang.org/)
- [ZLS](https://zigtools.org/zls/)
- [ziglang/shell-completions]

`~/.cache/zig` holds the build and package cache; persisting it as a volume keeps builds warm
across container rebuilds.

## Not installed

- **No `build-essential`.** The Zig bundle ships its own clang, linker, and libc headers, so
  `zig cc` covers C and C++ without a separate GNU toolchain. Add one only if a project needs
  `gcc` or `make` specifically.
- **No adjacent Zig tooling.** `zig fmt` and ZLS are the whole toolbox here; anything else is
  left to the project.

Unlike the version-manager images, the Zig version is fixed by the image tag. Zig is
pre-1.0 and its language and standard library still change between minor releases, so pin at
least the minor version (`0.16`) rather than `0`.

## Supply chain

The Zig tarball is downloaded from a [community mirror](https://ziglang.org/download/community-mirrors.txt)
with ziglang.org as the fallback, then verified with a minisign signature against Zig's public
key (`zig/zig-minisign.pub`); the signature's trusted comment is checked to name the requested
file, so a valid signature for a different release cannot be substituted. ZLS is verified the
same way against its own key (`zig/zls-minisign.pub`). Both keys are committed to this
repository and reviewed like any other change.

Shell completions are fetched from [ziglang/shell-completions] with `git` at a pinned commit
hash rather than by raw file URL, so the content is cryptographically bound to the reviewed
commit instead of trusting the server to serve honest content for it.

[ziglang/shell-completions]: https://codeberg.org/ziglang/shell-completions
