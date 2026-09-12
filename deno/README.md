# deno

Dev container image for JavaScript/TypeScript development, with the [Deno](https://deno.com/)
runtime installed, built on the [debian](../debian) base image.

Like every image in this repository, it is minimal, built only from upstreams verified at build
time, and published with SLSA provenance, a GitHub artifact attestation, and an SBOM; it runs as
the non-root user `dev`. [Why these images](../README.md#why-these-images) explains the
reasoning, and [Verifying the image](#verifying-the-image) below shows how to check a build.

## Image

```
ghcr.io/bare-devcontainer/deno:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/deno:2@sha256:<digest>"
}
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
| `2.9.6-trixie`, `2-trixie`, `trixie`, `2.9.6`, `2` | trixie |
| `2.9.6-bookworm`, `2-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `2.9.6-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Deno](https://deno.com/) (`deno`), with bash completions installed

Completions are generated at build time with `deno completions bash` and installed for the
`bash-completion` support already present in the [debian](../debian) base image.

## Not installed

- **No Node.js, `npm`, or `npx`.** Deno resolves `npm:` specifiers itself. A project that
  needs the Node.js runtime is better served by the [node](../node) image.
- **No global JavaScript tooling.** Deno's built-in formatter, linter, type checker, and test
  runner cover most of it; anything else is left to the project.

## Supply chain

`deno` is downloaded directly from [GitHub Releases](https://github.com/denoland/deno/releases).
Deno publishes neither a signature nor build provenance for its release archives, only a SHA-256
checksum on the same release, so each archive is verified against a copy of that checksum
committed to this repository (`deno/deno-<arch>.sha256`) rather than one fetched at build time.
The checksum files are taken from the release when the pinned `DENO_VERSION` changes, by an
automated workflow, and reviewed like any other change, so a build accepts only the archive that
was published when the version was pinned, and later tampering with the download channel cannot
affect builds.

## Verifying the image

Every build is published with SLSA provenance, a GitHub artifact attestation, and an SBOM. The
attestation confirms that an image was built by the release workflow of this repository and has
not been altered since:

```sh
gh attestation verify oci://ghcr.io/bare-devcontainer/deno:<tag>@sha256:<digest> \
  --owner bare-devcontainer
```

The attestation is looked up by digest, and the Docker Hub mirror carries the same digests, so
an image pulled from `docker.io/baredevcontainer/deno` verifies with the same command against
its own reference. [Verifying Published Images](../README.md#verifying-published-images) covers
inspecting the provenance and the SBOM as well.
