# mise

Dev container image with [mise](https://mise.jdx.dev/) installed, built on the [debian](../debian) base image.

mise is a polyglot runtime manager that can install and manage multiple language toolchains (Node.js, Python, Ruby, Go, etc.) per project.

The mise binary is downloaded from GitHub Releases and verified with a minisign signature before installation.

## Image

```
ghcr.io/bare-devcontainer/mise:<tag>
```

## Tags

| Tag | mise version | Debian version |
|-----|-------------|---------------|
| `2026.6.12-trixie`, `2026.6.12`, `trixie` | 2026.6.12 | trixie |
| `2026.6.12-bookworm`, `bookworm` | 2026.6.12 | bookworm |

Tags are also published with a date suffix (e.g., `trixie-20260623`) on each build.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [mise](https://mise.jdx.dev/)
- [usage](https://usage.jdx.dev/) (global mise tool; for CLI completion support)
