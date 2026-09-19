# Bare Dev Container Images

[![Lint](https://github.com/bare-devcontainer/images/actions/workflows/lint.yml/badge.svg)](https://github.com/bare-devcontainer/images/actions/workflows/lint.yml)
[![Build Checks](https://github.com/bare-devcontainer/images/actions/workflows/build-checks.yml/badge.svg)](https://github.com/bare-devcontainer/images/actions/workflows/build-checks.yml)
[![Trivy Scan](https://github.com/bare-devcontainer/images/actions/workflows/trivy.yml/badge.svg)](https://github.com/bare-devcontainer/images/actions/workflows/trivy.yml)
[![Attestation Checks](https://github.com/bare-devcontainer/images/actions/workflows/attest-check.yml/badge.svg?branch=main)](https://github.com/bare-devcontainer/images/actions/workflows/attest-check.yml)

Minimal, multi-arch Dev Container images: a small Debian base, plus one image per stack. Each
carries only what its target stack needs, is built from a small set of verified upstreams, and
ships with SLSA provenance, a GitHub artifact attestation, and an SBOM.

## Quick start

Pick the image for your stack from the [Images](#images) table and reference it from
`.devcontainer/devcontainer.json`:

```json
{
  "image": "ghcr.io/bare-devcontainer/golang:1.27"
}
```

Only the name and tag change between images — `node:26`, `uv:0.11.32`, `rustup:1`, or
`debian:trixie` for a project with no particular stack. The container runs as the non-root user
`dev` and starts in `/workspaces`.

For anything beyond a trial, pin the digest as well — see [Tags and pinning](#tags-and-pinning)
— and consider starting from the matching template in
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates), which adds
security hardening (all Linux capabilities dropped, `no-new-privileges`) and volume mounts that
persist the language and package manager caches across rebuilds.

## Why these images

A dev environment installs a lot of software from a lot of upstreams, which makes its supply
chain hard to keep trustworthy. These images are built to keep that surface small and the
contents auditable:

- **Minimal by construction** — each image carries only what its target stack needs, so there is
  less installed software to audit and to patch. [What's not included](#whats-not-included) is
  explicit about what that leaves out.
- **Unprivileged and ready to use** — every image runs as a non-root user that owns nothing
  outside its home directory and ships the Dev Container metadata a client needs to pick that
  user up. See [The `dev` user](#the-dev-user).
- **Minimal trusted upstreams** — software comes only from the Debian package archive, Docker
  Official Images, and each upstream's own distribution channel, verified by the method that
  upstream recommends, such as GPG or minisign. Each image's README documents its own.
- **Verifiable builds** — dependencies are pinned to versions and content digests, and every
  build publishes SLSA provenance, a GitHub artifact attestation, and an SBOM. See
  [Verifying Published Images](#verifying-published-images).
- **Regular base updates** — Renovate tracks the Debian base and each pinned upstream, so
  security patches are picked up promptly. [Tags and pinning](#tags-and-pinning) covers how a
  rebuild reaches a tag.

Microsoft publishes Dev Container base images too
([devcontainers/images](https://github.com/devcontainers/images)), but they are larger than
necessary and carry packages many projects never use. These images are the minimal alternative:
start from a small, auditable base and add exactly what the project needs.

## What's not included

These images are deliberately bare. Expect the following to be absent unless an image's own
README says otherwise:

- **No `sudo`, and no root shell.** Anything that needs root has to happen at build time in your
  own `Dockerfile`, or through a Dev Container Feature.
- **No development headers beyond libc.** The base image ships `build-essential`, so native
  extensions compile, but a library a project links against brings its own `-dev` package.
- **No editors, shells, or CLI tooling beyond the basics.** `bash` and `vim-tiny` are present;
  editors, alternative shells, cloud CLIs, and linters are not.
- **No language toolchain in the version-manager images.** `mise`, `pnpm`, `rustup`, and `uv`
  install the version the project declares rather than one baked into the image.

There are two ways to add what a project needs. A
[Dev Container Feature](https://containers.dev/features) layers in ready-made tooling from
`devcontainer.json` without a `Dockerfile`; CI verifies a representative set against the
`debian` base, covering the install mechanisms Features rely on, so they can be expected to work
across all of these images. Anything project-specific, or anything that needs root, goes in your
own `Dockerfile` built on one of these images — see [Usage](#usage).

## The `dev` user

Every image runs as `dev` (UID/GID 1000), starts in `/workspaces`, and declares `remoteUser` and
`containerUser` through the
[`devcontainer.metadata` label](https://containers.dev/implementors/reference/#labels), so a Dev
Container client picks the user up on its own. `dev` owns its home directory and nothing else,
so a client that remaps it to the host user's UID
([`updateRemoteUserUID`](https://containers.dev/implementors/json_reference/), on by default on
Linux) leaves no file behind under the old UID. CI asserts this on every image.

## Images

| Image | Registry | Use it for |
|-------|----------|------------|
| [bun](bun/README.md) | `ghcr.io/bare-devcontainer/bun` | JavaScript/TypeScript with the Bun runtime |
| [debian](debian/README.md) | `ghcr.io/bare-devcontainer/debian` | The base for every other image; language-agnostic projects |
| [deno](deno/README.md) | `ghcr.io/bare-devcontainer/deno` | JavaScript/TypeScript with the Deno runtime |
| [golang](golang/README.md) | `ghcr.io/bare-devcontainer/golang` | Go, with the toolchain version pinned by tag |
| [mise](mise/README.md) | `ghcr.io/bare-devcontainer/mise` | Polyglot projects that pin their own runtimes |
| [node](node/README.md) | `ghcr.io/bare-devcontainer/node` | Node.js, with Corepack instead of npm |
| [opentofu](opentofu/README.md) | `ghcr.io/bare-devcontainer/opentofu` | Infrastructure as code with OpenTofu |
| [pnpm](pnpm/README.md) | `ghcr.io/bare-devcontainer/pnpm` | Node.js, with the runtime version managed by pnpm |
| [rustup](rustup/README.md) | `ghcr.io/bare-devcontainer/rustup` | Rust, with the toolchain chosen by the project |
| [temurin](temurin/README.md) | `ghcr.io/bare-devcontainer/temurin` | Java, with the Eclipse Temurin JDK version pinned by tag |
| [terraform](terraform/README.md) | `ghcr.io/bare-devcontainer/terraform` | Infrastructure as code with Terraform |
| [uv](uv/README.md) | `ghcr.io/bare-devcontainer/uv` | Python, with the interpreter managed by uv |
| [zig](zig/README.md) | `ghcr.io/bare-devcontainer/zig` | Zig, with the compiler version pinned by tag |

Every image is published for `linux/amd64` and `linux/arm64`. See each image's README for its
available tags, the software it ships, and how its upstreams are verified.

The same builds are mirrored to Docker Hub as `docker.io/baredevcontainer/<image>`, with the
same tags and digests, so they stay available while `ghcr.io` is down. Prefer `ghcr.io`: it is
where each release lands first, and it has no
[pull rate limits](https://docs.docker.com/docker-hub/usage/pulls/).

## Tags and pinning

Each image publishes several tags per build. Using `golang` as an example:

| Tag | Points at | Moves when |
|-----|-----------|------------|
| `1.27.0-trixie` | An exact version on an exact Debian release | The image is rebuilt (base updates, security patches) |
| `1.27-trixie`, `1-trixie` | The newest matching version on that Debian release | A new patch or minor version is published |
| `trixie` | The newest version on that Debian release | Any build of the image |
| `1.27.0`, `1.27`, `1` | The same as the `-trixie` form; the default Debian release is implied | Same as the `-trixie` form |
| `1.27.0-trixie-20260727` | One specific build, by date | Never |

An image is rebuilt when its own definition or the shared Debian base changes, and every image
is rebuilt at least once a week. Because the base image and its packages are refreshed on every
build, **every tag except the date-suffixed ones is mutable**: the same tag resolves to
different content over time. That is what makes security patches arrive automatically, and also
why a tag alone is not a reproducible reference.

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

The common case — an image referenced directly, or the matching template from
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates) applied to the
project — is covered in [Quick start](#quick-start). A project that builds on top of an image,
or that runs more than one container, uses one of the two setups below instead.

### With a Dockerfile

Create a `Dockerfile` that extends one of the images, then reference it from
`.devcontainer/devcontainer.json`:

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

### With Docker Compose

Create a `compose.yml` that references the image, then reference it from
`.devcontainer/devcontainer.json`:

```yaml
services:
  app:
    image: ghcr.io/bare-devcontainer/golang:1.27@sha256:<digest>
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

Each image is published with artifacts that let you confirm where it came from and audit what is
in it.

### GitHub artifact attestation

Every image carries an attestation generated by the build pipeline with
[actions/attest](https://github.com/actions/attest).
[`gh attestation verify`](https://cli.github.com/manual/gh_attestation_verify) confirms that the
image was built by the official workflow in this repository and has not been tampered with:

```sh
gh attestation verify oci://ghcr.io/bare-devcontainer/<image>:<tag>@sha256:<digest> \
  --owner bare-devcontainer
```

The attestations are held by GitHub and looked up by digest, and the Docker Hub mirror carries
the same digests, so an image pulled from `docker.io/baredevcontainer/<image>` verifies with the
same command against its own reference.

### Build provenance

A SLSA provenance attestation generated by Docker Buildx is embedded in each OCI manifest. It
records where and how the image was built:

```sh
docker buildx imagetools inspect ghcr.io/bare-devcontainer/<image>:<tag>@sha256:<digest> \
  --format '{{json .Provenance}}'
```

### SBOM

A Software Bill of Materials in [SPDX](https://spdx.dev/) format is embedded in the same
manifest. It lists the packages the image contains:

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
