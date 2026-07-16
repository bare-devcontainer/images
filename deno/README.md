# deno

Dev container image for JavaScript/TypeScript development, with the [Deno](https://deno.com/)
runtime installed, built on the [debian](../debian) base image.

`deno` is downloaded directly from [GitHub Releases](https://github.com/denoland/deno/releases).
Deno publishes no signature for its release archives, so the download is verified against a
SHA-256 checksum file committed to this repository (`deno/deno-<arch>.sha256`) rather than one
fetched from the same server as the archive. The committed checksum files are kept in sync with
the pinned `DENO_VERSION` by an automated workflow and reviewed like any other change, so later
tampering with the download channel cannot affect builds.

Bash completions are generated at build time with `deno completions bash` and installed for the
`bash-completion` support already present in the [debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/deno:<tag>
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/deno).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `2.9.2-trixie`, `2-trixie`, `trixie`, `2.9.2`, `2` | trixie |
| `2.9.2-bookworm`, `2-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `2.9.2-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Deno](https://deno.com/) (`deno`), with bash completions installed
