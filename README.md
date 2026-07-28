# Bare Dev Container Images

[![Lint](https://github.com/bare-devcontainer/images/actions/workflows/lint.yml/badge.svg)](https://github.com/bare-devcontainer/images/actions/workflows/lint.yml)
[![Build Checks](https://github.com/bare-devcontainer/images/actions/workflows/build-checks.yml/badge.svg)](https://github.com/bare-devcontainer/images/actions/workflows/build-checks.yml)
[![Trivy Scan](https://github.com/bare-devcontainer/images/actions/workflows/trivy.yml/badge.svg)](https://github.com/bare-devcontainer/images/actions/workflows/trivy.yml)
[![Attestation Checks](https://github.com/bare-devcontainer/images/actions/workflows/attest-check.yml/badge.svg?branch=main)](https://github.com/bare-devcontainer/images/actions/workflows/attest-check.yml)

Minimal, multi-arch Dev Container images: a small Debian base, plus one image per stack for
Go, Node.js, Deno, Bun, Python, Rust, Zig, and Terraform, and one with mise for polyglot
projects. Each carries only what its target stack needs, is built from a small set of verified
upstreams, and ships with SLSA provenance, a GitHub artifact attestation, and an SBOM.

## Quick start

Reference an image from `.devcontainer/devcontainer.json` and reopen the project in a
container:

```json
{
  "image": "ghcr.io/bare-devcontainer/debian:trixie"
}
```

The container runs as the non-root user `dev` and starts in `/workspaces`. For anything
beyond a trial, pin the digest as well — see [Tags and pinning](#tags-and-pinning) — and
consider starting from the matching template in
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates), a companion
repository to this one, which adds the recommended security hardening and cache mounts.

## Why these images

A dev container downloads and executes software from a long list of upstream servers: package
archives, release CDNs, GitHub Releases, install scripts piped into a shell. Each one is a
place where a compromise lands directly on a developer's machine, and unpinned versions and
unverified downloads make it hard to tell afterwards what was actually installed. These
images are built to keep that surface small and the contents auditable:

- **Dev Container ready** — Each image comes with standard Dev Container configuration pre-applied, so it works out of the box.
- **Minimal attack surface** — Each image includes only the packages and configuration required for its target stack. Keeping installed software to a minimum helps reduce the potential vulnerability surface of each development environment.
- **Minimal trusted upstreams** — Software is sourced only from the official Debian package archive, Docker Official Images, and the official distribution channels for each language runtime or package manager. Packages are verified using the officially recommended methods for each upstream, such as GPG or minisign.
- **Secure build pipeline** — All dependencies are pinned to specific versions and content digests. Published images include SLSA provenance attestations, making the build process verifiable.
- **Regular base updates** — Debian base images are updated regularly with Renovate so upstream security patches can be incorporated promptly.

Dev Container base images are also available from Microsoft ([devcontainers/images](https://github.com/devcontainers/images)),
but they are often larger than necessary and include many packages that may not be needed for
a given development environment. These images are intended to provide a more minimal
alternative: start from a small, auditable base and add exactly what the project needs.

## What's not included

These images are deliberately bare. Expect the following to be absent unless an image's own
README says otherwise:

- **No `sudo`, and no root shell.** The image runs as the non-root user `dev` (UID/GID 1000).
  Anything that needs root has to happen at build time in your own `Dockerfile`, or through a
  Dev Container Feature.
- **No build toolchain unless the stack needs one.** Compilers and headers are installed only
  in the images whose ecosystem requires them.
- **No editors, shells, or CLI tooling beyond the basics.** `bash` and `vim-tiny` are present;
  editors, alternative shells, cloud CLIs, and linters are not.
- **No language toolchain in the version-manager images.** `mise`, `rustup`, and `uv` install
  the version the project declares rather than one baked into the image. The `Not installed`
  section of each image's README states exactly what is left out.

There are two ways to add what a project needs on top:

1. **[Dev Container Features](https://containers.dev/features)** — the usual way to layer in
   ready-made tooling such as the GitHub CLI or Git LFS, configured in `devcontainer.json`
   without writing a `Dockerfile`. CI verifies a representative set of Features against the
   `debian` base, covering the install mechanisms Features generally rely on, so they can be
   expected to work across all of these images.
2. **Your own `Dockerfile`, using one of these images as its base** — for anything
   project-specific, or anything that needs root. `FROM` an image here and install on top of
   it:

   ```dockerfile
   FROM ghcr.io/bare-devcontainer/node:26@sha256:<digest>

   USER root
   RUN corepack enable
   USER dev
   ```

   See [Using with a Dockerfile](#using-with-a-dockerfile) for how to wire that into
   `devcontainer.json`.

## Images

| Image | Registry | Use it for |
|-------|----------|------------|
| [bun](bun/README.md) | `ghcr.io/bare-devcontainer/bun` | JavaScript/TypeScript with the Bun runtime |
| [debian](debian/README.md) | `ghcr.io/bare-devcontainer/debian` | The base for every other image; language-agnostic projects |
| [deno](deno/README.md) | `ghcr.io/bare-devcontainer/deno` | JavaScript/TypeScript with the Deno runtime |
| [golang](golang/README.md) | `ghcr.io/bare-devcontainer/golang` | Go, with the toolchain version pinned by tag |
| [mise](mise/README.md) | `ghcr.io/bare-devcontainer/mise` | Polyglot projects that pin their own runtimes |
| [node](node/README.md) | `ghcr.io/bare-devcontainer/node` | Node.js, with Corepack instead of npm |
| [rustup](rustup/README.md) | `ghcr.io/bare-devcontainer/rustup` | Rust, with the toolchain chosen by the project |
| [terraform](terraform/README.md) | `ghcr.io/bare-devcontainer/terraform` | Infrastructure as code with Terraform |
| [uv](uv/README.md) | `ghcr.io/bare-devcontainer/uv` | Python, with the interpreter managed by uv |
| [zig](zig/README.md) | `ghcr.io/bare-devcontainer/zig` | Zig, with the compiler version pinned by tag |

Every image is published for `linux/amd64` and `linux/arm64`. See each image's README for its
available tags, the software it ships, and how its upstreams are verified.

## Tags and pinning

Each image publishes several tags per build. Using `golang` as an example:

| Tag | Points at | Moves when |
|-----|-----------|------------|
| `1.26.5-trixie` | An exact version on an exact Debian release | The image is rebuilt (base updates, security patches) |
| `1.26-trixie`, `1-trixie` | The newest matching version on that Debian release | A new patch or minor version is published |
| `trixie` | The newest version on that Debian release | Any release |
| `1.26.5`, `1.26`, `1` | The same as the `-trixie` form; the default Debian release is implied | Same as the `-trixie` form |
| `1.26.5-trixie-20260727` | One specific build, by date | Never |

Because the base image and its packages are refreshed on every build, **every tag except the
date-suffixed ones is mutable**: the same tag resolves to different content over time. That is
what makes security patches arrive automatically, and also why a tag alone is not a
reproducible reference.

> [!TIP]
> Pin the digest as well as the tag (`image:tag@sha256:...`). The tag stays readable, the
> digest makes the reference exact, and [Renovate](https://docs.renovatebot.com/) or
> Dependabot can raise a reviewable pull request whenever a new build is published. Find the
> digest on the [GitHub Container Registry](https://github.com/orgs/bare-devcontainer/packages)
> page, or with:
> ```sh
> docker buildx imagetools inspect ghcr.io/bare-devcontainer/<image>:<tag>
> ```

## Usage

### Using a Dev Container Template (Recommended)

The quickest way to get started is to use one of the pre-built templates from the [bare-devcontainer/templates](https://github.com/bare-devcontainer/templates) repository. Each image in this repository has a corresponding template that provides the recommended Dev Container configuration out of the box, including security hardening (dropping all Linux capabilities, `no-new-privileges`, running as a non-root user) and volume mounts that persist language and package manager cache directories for faster rebuilds.

### Using Directly in devcontainer.json

Reference an image directly in `.devcontainer/devcontainer.json`:

```json
{
  "image": "ghcr.io/bare-devcontainer/debian:trixie@sha256:<digest>"
}
```

### Using with a Dockerfile

Create a `Dockerfile` that extends one of the images, then reference it from `.devcontainer/devcontainer.json`:

```dockerfile
FROM ghcr.io/bare-devcontainer/rustup:1@sha256:<digest>

# Add your project-specific setup here.
# The image ships no Rust toolchain, so install one before invoking cargo.
RUN rustup toolchain install stable && cargo install cargo-watch
```

```json
{
  "build": {
    "dockerfile": "Dockerfile"
  }
}
```

### Using with Docker Compose

Create a `compose.yml` that references the image, then reference it from `.devcontainer/devcontainer.json`:

```yaml
services:
  app:
    image: ghcr.io/bare-devcontainer/golang:1.26@sha256:<digest>
    volumes:
      - ..:/workspaces
    command: sleep infinity
```

```json
{
  "dockerComposeFile": "compose.yml",
  "service": "app",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}"
}
```

## Verifying Published Images

Before using an image, you can confirm its authenticity and audit its contents using the artifacts published alongside each image. The GitHub artifact attestation lets you verify that the image was built by the official pipeline and has not been tampered with. The build provenance and SBOM embedded in the OCI manifest let you inspect where and how the image was built, and what packages it contains.

### GitHub Artifact Attestation

All published images include artifact attestations generated by the build pipeline using [actions/attest](https://github.com/actions/attest). You can verify an image using the [`gh attestation verify`](https://cli.github.com/manual/gh_attestation_verify) command:

```sh
gh attestation verify oci://ghcr.io/bare-devcontainer/<image>:<tag>@sha256:<digest> \
  --owner bare-devcontainer
```

For example:

```sh
gh attestation verify oci://ghcr.io/bare-devcontainer/golang:1.26@sha256:<digest> \
  --owner bare-devcontainer
```

A successful verification confirms that the image was built by the official GitHub Actions workflow in this repository and has not been tampered with.

### Build Provenance

Each image also includes a SLSA provenance attestation embedded in the OCI manifest, generated by Docker Buildx. You can inspect it with:

```sh
docker buildx imagetools inspect ghcr.io/bare-devcontainer/<image>:<tag>@sha256:<digest> \
  --format '{{json .Provenance}}'
```

### SBOM

A Software Bill of Materials (SBOM) in [SPDX](https://spdx.dev/) format is embedded in the OCI manifest for each image. You can inspect it with:

```sh
docker buildx imagetools inspect ghcr.io/bare-devcontainer/<image>:<tag>@sha256:<digest> \
  --format '{{json .SBOM}}'
```

## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md).

## Contributing

Bug reports, image requests, and pull requests are welcome. [AGENTS.md](AGENTS.md) describes
how the repository is laid out and the conventions a change is expected to follow.

## License

[MIT](LICENSE)
