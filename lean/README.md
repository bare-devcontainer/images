# lean (elan)

Dev container image for Lean 4 development, with [elan](https://github.com/leanprover/elan)
installed, built on the [debian](../debian) base image.

Like every image in this repository, it is minimal, built only from upstreams verified at build
time, and published with SLSA provenance, a GitHub artifact attestation, and an SBOM; it runs as
the non-root user `dev`. [Why these images](../README.md#why-these-images) explains the
reasoning, and [Verifying the image](#verifying-the-image) below shows how to check a build.

## Image

```
ghcr.io/bare-devcontainer/lean:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/lean:4@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/lean).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `4.2.4-trixie`, `4-trixie`, `trixie`, `4.2.4`, `4` | trixie |
| `4.2.4-bookworm`, `4-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `4.2.4-trixie-<YYYYMMDD>`).
<!-- tags:end -->

The version in these tags is the version of `elan` itself, not of any Lean toolchain.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [elan](https://github.com/leanprover/elan), the Lean toolchain manager

`~/.elan/bin` is on `PATH` under a Dev Container client, so the `elan`, `lean`, and `lake` shims
resolve once a toolchain is installed. Running the image without one (`docker run`, a CI job's
`container:`) leaves the directory off `PATH`.

## Not installed

- **No Lean toolchain.** `lean`, `lake`, and the Lean language server arrive when `elan`
  installs the toolchain the project asks for, so the version in use is the one the project
  declares rather than the one this image happens to ship.
- **No libraries.** Mathlib and other Lake dependencies are fetched per project by `lake`.

## Working with toolchains

A project that pins its toolchain in `lean-toolchain` needs no setup: the first `lean` or
`lake` invocation installs the pinned toolchain. To install it up front instead of on first
use, run `lake --version` from a `postCreateCommand` in the project directory. Without a
`lean-toolchain`, install a toolchain explicitly and make it the default with
`elan default stable`.

A project depending on Mathlib can download its prebuilt build outputs with
`lake exe cache get` instead of compiling Mathlib locally.

Two directories are worth persisting across container rebuilds as volumes:

- `~/.elan/toolchains` — the installed toolchains. Toolchains are re-downloaded on every
  rebuild unless this directory survives. Persist it rather than all of `~/.elan`, whose `bin`
  holds the `elan` this image verified; a volume there would keep the old `elan` after the
  image is updated.
- `~/.cache/mathlib` — the prebuilt Mathlib outputs `lake exe cache get` downloads.

## Supply chain

`elan` is downloaded directly from its [GitHub Releases](https://github.com/leanprover/elan/releases).
elan publishes neither a checksum, a signature, nor build provenance for its release tarballs,
so each tarball is verified against a SHA-256 checksum committed to this repository
(`lean/elan-<arch>.sha256`). The committed checksum is derived from the release tarball only
after it matches the digest GitHub recorded for the release asset, is kept in sync with the
pinned `ELAN_VERSION` by an automated workflow, and is reviewed like any other change, so later
tampering with the download channel cannot affect builds.

`elan` does not replace itself when it installs a toolchain; it only reports that a newer
release exists. Running `elan self update` replaces it with a download this image did not
verify.

Note that this covers `elan` itself. Toolchains it installs at runtime are downloaded from
release.lean-lang.org and the [leanprover/lean4](https://github.com/leanprover/lean4) releases
outside this image's build pipeline, with no signature verified.

## Verifying the image

Every build is published with SLSA provenance, a GitHub artifact attestation, and an SBOM. The
attestation confirms that an image was built by the release workflow of this repository and has
not been altered since:

```sh
gh attestation verify oci://ghcr.io/bare-devcontainer/lean:<tag>@sha256:<digest> \
  --owner bare-devcontainer
```

The Docker Hub mirror carries the same digests, so the same command verifies an image pulled
from `docker.io/baredevcontainer/lean`.
[Verifying Published Images](../README.md#verifying-published-images) covers inspecting the
provenance and the SBOM as well.
