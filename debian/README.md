# debian

Minimal Debian base image for dev containers. All other images in this repository extend this image.

Like every image in this repository, it is minimal, built only from upstreams verified at build
time, and published with SLSA provenance, a GitHub artifact attestation, and an SBOM; it runs as
the non-root user `dev`. [Why these images](../README.md#why-these-images) explains the
reasoning, and [Verifying the image](#verifying-the-image) below shows how to check a build.

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

`dev` owns its home directory and nothing else, so the image works with any host UID: a client
that remaps `dev` to the UID and GID of the user running it re-owns the home directory and
leaves nothing behind under the old one. `/workspaces` is created as root for that reason, and
a dev container covers it with the workspace bind mount.
[The `dev` user](../README.md#the-dev-user) covers what that guarantees.

`dev`'s login shell is bash, which appends each command to `$HISTFILE` as it is entered rather
than at exit. `HISTFILE` is `/home/dev/.local/state/bash/history` rather than the default
`~/.bash_history`, and that directory is created in the image, so mounting a volume on it keeps
the shell history across container rebuilds, which is what the
[Dev Container template](#dev-container-template) does.

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

## Verifying the image

Every build is published with SLSA provenance, a GitHub artifact attestation, and an SBOM. The
attestation confirms that an image was built by the release workflow of this repository and has
not been altered since:

```sh
gh attestation verify oci://ghcr.io/bare-devcontainer/debian:<tag>@sha256:<digest> \
  --owner bare-devcontainer
```

The attestation is looked up by digest, and the Docker Hub mirror carries the same digests, so
an image pulled from `docker.io/baredevcontainer/debian` verifies with the same command against
its own reference. [Verifying Published Images](../README.md#verifying-published-images) covers
inspecting the provenance and the SBOM as well.
