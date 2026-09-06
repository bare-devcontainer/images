# bun

Dev container image for JavaScript/TypeScript development, with the [Bun](https://bun.com/)
runtime installed, built on the [debian](../debian) base image.

Like every image in this repository, it is minimal, built only from upstreams verified at build
time, and published with SLSA provenance, a GitHub artifact attestation, and an SBOM; it runs as
the non-root user `dev`. [Why these images](../README.md#why-these-images) explains the
reasoning, and [Verifying the image](#verifying-the-image) below shows how to check a build.

## Image

```
ghcr.io/bare-devcontainer/bun:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/bun:1@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/bun).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `1.4.2-trixie`, `1-trixie`, `1.4.2`, `1`, `trixie` | trixie |
| `1.4.2-bookworm`, `1-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `1.4.2-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Bun](https://bun.com/) (`bun`, `bunx`)

## Not installed

- **No Node.js, `npm`, or `npx`.** Bun runs the scripts and installs the packages. A project
  that also needs the Node.js runtime is better served by the [node](../node) image.
- **No global JavaScript tooling.** Linters, formatters, and test runners are left to the
  project's own dependencies; Bun's built-in test runner and bundler cover part of that ground.

## Supply chain

`bun` is downloaded directly from [GitHub Releases](https://github.com/oven-sh/bun/releases).
Its checksum is verified against `SHASUMS256.txt`, whose GPG signature (`SHASUMS256.txt.asc`) is
verified against Bun's release signing key before installation. The key
(`bun/bun-signing-key.asc`) is committed to this repository, so signatures are checked against
a key reviewed here rather than one fetched at build time.

## Verifying the image

Every build is published with SLSA provenance, a GitHub artifact attestation, and an SBOM. The
attestation confirms that an image was built by the release workflow of this repository and has
not been altered since:

```sh
gh attestation verify oci://ghcr.io/bare-devcontainer/bun:<tag>@sha256:<digest> \
  --owner bare-devcontainer
```

The attestation is looked up by digest, and the Docker Hub mirror carries the same digests, so
an image pulled from `docker.io/baredevcontainer/bun` verifies with the same command against
its own reference. [Verifying Published Images](../README.md#verifying-published-images) covers
inspecting the provenance and the SBOM as well.
