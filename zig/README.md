# zig

Dev container image with the Zig compiler installed, built on the [debian](../debian) base image.

The Zig binary is downloaded from ziglang.org and verified with a minisign signature before installation. Bash completions are also installed from the [ziglang/shell-completions] repository.

## Image

```
ghcr.io/bare-devcontainer/zig:<tag>
```

## Tags

| Tag | Zig version | Debian version |
|-----|------------|---------------|
| `0.16.0-trixie`, `0.16-trixie`, `0-trixie`, `0.16.0`, `0.16`, `0` | 0.16.x | trixie |
| `0.16.0-bookworm`, `0.16-bookworm` | 0.16.x | bookworm |
| `0.15.2-trixie`, `0.15-trixie`, `0.15.2`, `0.15` | 0.15.x | trixie |
| `0.15.2-bookworm`, `0.15-bookworm` | 0.15.x | bookworm |

Tags are also published with a date suffix (e.g., `0.16-trixie-20260623`) on each build.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Zig bundle](https://ziglang.org/)
- [ZLS](https://zigtools.org/zls/)
- [ziglang/shell-completions]

[ziglang/shell-completions]: https://codeberg.org/ziglang/shell-completions
