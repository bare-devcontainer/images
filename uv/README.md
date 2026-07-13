# uv (python)

Dev container image for Python development, with [uv](https://docs.astral.sh/uv/)
installed, built on the [debian](../debian) base image.

`uv` is downloaded directly from [GitHub Releases](https://github.com/astral-sh/uv/releases)
and its checksum is verified before installation. It is also verified against its
[GitHub Artifact Attestation](https://docs.github.com/en/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds)
using `gh attestation verify`, which runs fully unauthenticated at build time (the
attestation bundle is fetched from GitHub's public REST API). The `gh` CLI used for
this verification is installed in the builder stage from
[GitHub's official apt repository](https://cli.github.com/packages), whose signing
keyring is committed to this repository and kept in sync by the update-keys workflow.

## Image

```
ghcr.io/bare-devcontainer/uv:<tag>
```

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `0.11.28-trixie`, `0.11.28`, `trixie` | trixie |
| `0.11.28-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `0.11.28-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [uv](https://docs.astral.sh/uv/) (`uv`, `uvx`)

Note that Python itself is not installed by default since most projects will specify a
version in a `.python-version` file or their `pyproject.toml`'s `requires-python`. `uv`
downloads and manages the matching CPython automatically on demand.
