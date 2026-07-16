# deno

Dev container image for JavaScript/TypeScript development, with the [Deno](https://deno.com/)
runtime installed, built on the [debian](../debian) base image.

`deno` is downloaded directly from [GitHub Releases](https://github.com/denoland/deno/releases)
and its checksum is verified before installation. It is also verified against its
[GitHub Artifact Attestation](https://docs.github.com/en/actions/security-guides/using-artifact-attestations-to-establish-provenance-for-builds)
using `gh release verify-asset`. Deno's release archives carry GitHub's automatic
`https://in-toto.io/attestation/release/v0.2` release attestation rather than a SLSA build
provenance attestation, so this confirms the archive was genuinely published as part of that
GitHub release rather than proving the build process that produced it. `gh release verify-asset`
requires an authenticated token, supplied as a `github_token` build secret from the publish
workflow's ambient `GITHUB_TOKEN` (reading public attestation data needs no special permissions).
The disposable devcontainer sandbox build used for CI smoke tests has no way to supply build
secrets, so it explicitly skips this check via the `SKIP_ATTESTATION_VERIFY` build arg; the
published image always verifies it.

Bash completions are generated at build time with `deno completions bash` and installed for the
`bash-completion` support already present in the [debian](../debian) base image.

## Image

```
ghcr.io/bare-devcontainer/deno:<tag>
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
| `2.9.2-trixie`, `2-trixie`, `trixie`, `2.9.2`, `2` | trixie |
| `2.9.2-bookworm`, `2-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `2.9.2-trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Deno](https://deno.com/) (`deno`), with bash completions installed
