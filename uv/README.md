# uv (python)

Dev container image for Python development, with [uv](https://docs.astral.sh/uv/)
installed, built on the [debian](../debian) base image.

`uv` is downloaded directly from [GitHub Releases](https://github.com/astral-sh/uv/releases)
and verified before installation against a checksum committed to this repository.
The checksum is sourced from [releases.astral.sh](https://releases.astral.sh/) and
kept in sync with the pinned version by `.github/workflows/update-material.yml`, so it
is reviewed like any other change rather than fetched alongside the binary at build time.

## Image

```
ghcr.io/bare-devcontainer/uv:<tag>
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/uv).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `0.11.30-trixie`, `0.11.30`, `trixie` | trixie |
| `0.11.30-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `0.11.30-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [uv](https://docs.astral.sh/uv/) (`uv`, `uvx`)

Note that Python itself is not installed by default since most projects will specify a
version in a `.python-version` file or their `pyproject.toml`'s `requires-python`. `uv`
downloads and manages the matching CPython automatically on demand.
