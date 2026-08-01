# debian

Minimal Debian base image for dev containers. All other images in this repository extend this image.

## Image

```
ghcr.io/bare-devcontainer/debian:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/debian:trixie@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/debian).
It provides the recommended configuration for this image, including security hardening.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `trixie` | trixie |
| `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

- **Git & SSH**: `git`, `openssh-client`, `gnupg2`
- **Network**: `ca-certificates`, `iproute2`, `curl`, `wget`
- **System utilities**: `procps`, `lsof`, `psmisc`
- **Archive utilities**: `unzip`, `bzip2`, `xz-utils`, `zip`, `zlib1g`
- **File utilities**: `less`, `jq`, `vim-tiny`
- **Scripting**: `python3`
- **C/C++ build toolchain**: `build-essential` (`gcc`, `g++`, `make`, and the libc headers)
- **Misc**: `bash-completion`, `lsb-release`, `locales` (en_US.UTF-8), `man-db`, `manpages`

The image runs as the non-root user `dev` (UID/GID 1000) and its working directory is
`/workspaces`. `remoteUser` and `containerUser` are declared through the
[`devcontainer.metadata` label](https://containers.dev/implementors/reference/#labels), so Dev
Container clients pick up the user without extra configuration. Every image built on this one
inherits that label.

## Not installed

- **No development headers beyond libc.** `build-essential` covers the compiler, linker, and
  libc headers, so a self-contained C or C++ source build works. Code that links against a
  third-party library still needs that library's `-dev` package.
- **No `sudo`.** Nothing in the container can escalate to root. Install packages at build
  time in your own `Dockerfile` (which runs as root) or through a Dev Container Feature.
- **No language runtime for development.** `python3` is present so that scripts and tooling
  that assume a system Python keep working; it is not intended as a project interpreter. Use
  the [uv](../uv), [mise](../mise), or another language image for that.
- **No editor or shell beyond the basics.** `bash` and `vim-tiny` only.

## Supply chain

The image is built `FROM` the [Docker Official `debian` image](https://hub.docker.com/_/debian),
pinned in `build.yaml` to both a tag and a content digest so a build always resolves to the
exact base that was reviewed. Renovate raises a pull request whenever a new Debian base is
published. All other software comes from the Debian package archive over `apt`, which verifies
the archive's signatures on every install.
