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
| `2026.7.5-trixie`, `2026.7.5`, `trixie` | 2026.7.5 | trixie |

Tags are also published with a date suffix (e.g., `2026.7.5-trixie-20260623`) on each build.

> [!NOTE]
> The `bookworm` variant has been discontinued. mise 2026.7.0 and later require
> a newer glibc than bookworm provides, and mise uses calendar versioning, so
> no future mise release will ever be compatible with bookworm again. Rather
> than publishing a permanently frozen mise that no longer receives security
> fixes, only the trixie variant is maintained. Previously published bookworm
> tags remain available on GHCR but will not be updated.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [mise](https://mise.jdx.dev/)
- [usage](https://usage.jdx.dev/) (global mise tool; for CLI completion support)
