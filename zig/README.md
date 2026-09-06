# zig

Dev container image with the Zig compiler installed, built on the [debian](../debian) base image.

Like every image in this repository, it is built to keep the supply chain of a development
environment small and auditable: it carries only what Zig development needs, installs software
only from upstreams verified at build time, runs as a non-root user, and is published with SLSA
provenance, a GitHub artifact attestation, and an SBOM. The reasoning is in
[Why these images](../README.md#why-these-images); the [Supply chain](#supply-chain) section
below describes how this image's upstreams are verified, and
[Verifying the image](#verifying-the-image) how to check a build before using it.

## Image

```
ghcr.io/bare-devcontainer/zig:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/zig:0.16@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/zig).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `0.16.0-trixie`, `0.16-trixie`, `0-trixie`, `trixie`, `0.16.0`, `0.16`, `0` | trixie |
| `0.16.0-bookworm`, `0.16-bookworm`, `bookworm` | bookworm |
| `0.15.2-trixie`, `0.15-trixie`, `0.15.2`, `0.15` | trixie |
| `0.15.2-bookworm`, `0.15-bookworm` | bookworm |
| `master-trixie`, `master` | trixie |

Tags are also published with a date suffix on each build (e.g., `0.16.0-trixie-<YYYYMMDD>`).
<!-- tags:end -->

Besides the release tags, the `master` tags carry the master builds Zig publishes, refreshed
daily.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Zig bundle](https://ziglang.org/)
- [ZLS](https://zigtools.org/zls/)
- [ziglang/shell-completions]

`~/.cache/zig` holds the build and package cache; persisting it as a volume keeps builds warm
across container rebuilds.

## Not installed

- **No adjacent Zig tooling.** `zig fmt` and ZLS are the whole toolbox here; anything else is
  left to the project.

## Supply chain

The Zig tarball is downloaded from a [community mirror](https://ziglang.org/download/community-mirrors.txt)
with ziglang.org as the fallback, then verified with a minisign signature against Zig's public
key (`zig/zig-minisign.pub`); the signature's trusted comment is checked to name the requested
file, so a valid signature for a different release cannot be substituted. ZLS is verified the
same way against its own key (`zig/zls-minisign.pub`). Both keys are committed to this
repository and reviewed like any other change.

Shell completions are fetched from [ziglang/shell-completions] with `git` at a pinned commit
hash rather than by raw file URL, so the content is cryptographically bound to the reviewed
commit instead of trusting the server to serve honest content for it.

## Verifying the image

Every build is published with SLSA provenance, a GitHub artifact attestation, and an SBOM. The
attestation confirms that an image was built by the release workflow of this repository and has
not been altered since:

```sh
gh attestation verify oci://ghcr.io/bare-devcontainer/zig:<tag>@sha256:<digest> \
  --owner bare-devcontainer
```

The attestation is looked up by digest, and the Docker Hub mirror carries the same digests, so
an image pulled from `docker.io/baredevcontainer/zig` verifies with the same command against
its own reference. [Verifying Published Images](../README.md#verifying-published-images) covers
inspecting the provenance and the SBOM as well.

[ziglang/shell-completions]: https://codeberg.org/ziglang/shell-completions
