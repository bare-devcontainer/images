# uv (python)

Dev container image for Python development, with [uv](https://docs.astral.sh/uv/)
installed, built on the [debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/uv:<tag>
```

```json
{
  "image": "ghcr.io/bare-devcontainer/uv:0.11.32@sha256:<digest>"
}
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
| `0.11.32-trixie`, `0.11.32`, `trixie` | trixie |
| `0.11.32-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `0.11.32-trixie-<YYYYMMDD>`).
<!-- tags:end -->

The version in these tags is the version of `uv` itself, not of any Python interpreter.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [uv](https://docs.astral.sh/uv/) (`uv`, `uvx`), with bash completions installed

`~/.local/bin` is on `PATH`, so tools installed with `uv tool install` resolve without
further setup.

## Not installed

- **No project Python interpreter.** uv downloads and manages the CPython version the project
  declares in `.python-version` or in `pyproject.toml`'s `requires-python`, so the version in
  use is the one the project asks for. The base image's system `python3` exists for scripting
  and is not the interpreter uv builds environments from.
- **No `pip`, `pipx`, or `virtualenv`.** uv covers those workflows; `uv pip` provides a
  pip-compatible interface against the project's environment.
- **No C/C++ build toolchain.** uv installs prebuilt wheels where they exist; packages with no
  wheel for the platform must be compiled and need a toolchain added first.

## Working with interpreters

`uv sync` creates the project's environment and installs the interpreter it needs; `uv run`
does the same on first use. To do it when the container is created rather than on first use,
run `uv sync` from a `postCreateCommand`.

Two directories are worth persisting across container rebuilds as volumes:

- `~/.local/share/uv` — the managed Python installations. Interpreters are re-downloaded on
  every rebuild unless this directory survives.
- `~/.cache/uv` — the wheel and download cache.

## Supply chain

`uv` is downloaded directly from [GitHub Releases](https://github.com/astral-sh/uv/releases)
and verified before installation against a checksum committed to this repository.
The checksum is sourced from [releases.astral.sh](https://releases.astral.sh/) and
kept in sync with the pinned version by `.github/workflows/update-material.yml`, so it
is reviewed like any other change rather than fetched alongside the binary at build time.

Note that this covers the `uv` binary only. Interpreters and packages that uv installs at
runtime are fetched from their own upstreams under uv's own verification, outside this image's
build pipeline.
