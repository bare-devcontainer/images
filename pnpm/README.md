# pnpm

Dev container image with [pnpm](https://pnpm.io/) installed, built on the [debian](../debian)
base image. pnpm installs the Node.js version the project asks for, so the runtime is chosen by
the project rather than baked into the image.

## Image

```
ghcr.io/bare-devcontainer/pnpm:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/pnpm:12@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/pnpm).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `12.3.1-trixie`, `12-trixie`, `12.3.1`, `12`, `trixie` | trixie |
| `12.3.1-bookworm`, `12-bookworm`, `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `12.3.1-trixie-<YYYYMMDD>`).
<!-- tags:end -->

The version in these tags is the version of pnpm itself, not of any Node.js runtime.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [pnpm](https://pnpm.io/) (`pnpm`), with bash completions installed

pnpm is installed under `/opt/pnpm` with a `/usr/local/bin/pnpm` symlink, the layout of pnpm's
own [`ghcr.io/pnpm/pnpm`](https://pnpm.io/docker#official-pnpm-base-image) image. `PNPM_HOME` is
set to `~/.local/share/pnpm` and its `bin` directory is on `PATH`, so runtimes and globally
installed packages resolve without further setup.

## Not installed

- **No Node.js.** pnpm downloads and manages the runtime the project declares in
  [`devEngines.runtime`](https://pnpm.io/package_json#devenginesruntime), so the version in use is
  the one the project asks for. See [Working with runtimes](#working-with-runtimes) below.
- **No `npm`, `npx`, or Corepack.** pnpm covers those workflows, and installing a Node.js runtime
  with pnpm deliberately leaves the bundled `npm` unextracted. Run `pnpm add -g npm` if a project
  needs it. For a project whose package manager is not pnpm, use the [node](../node) image instead.
- **No global JavaScript tooling.** Linters, formatters, and test runners are left to the
  project's own dependencies.

## Working with runtimes

Declare the runtime in the project's `package.json` and pnpm installs it on first use:

```json
{
  "devEngines": {
    "runtime": { "name": "node", "version": "^24.0.0", "onFail": "download" }
  }
}
```

Inside that project a bare `node` runs the pinned version, because pnpm's global `node` is a shim
that dispatches to what the project asks for. Outside any project it runs the globally installed
version, which is set with [`pnpm runtime`](https://pnpm.io/cli/runtime):

```sh
pnpm runtime set node lts -g
```

To install the project's runtime and dependencies when the container is created rather than on
first use, run `pnpm install` from a `postCreateCommand`.

Two directories are worth persisting across container rebuilds as volumes:

- `~/.local/share/pnpm` — the store, the managed runtimes, and the bins of globally installed
  packages. All of it is re-downloaded on every rebuild unless this directory survives.
- `~/.cache/pnpm` — the metadata cache.

## Supply chain

pnpm is downloaded from [GitHub Releases](https://github.com/pnpm/pnpm/releases), the same archive
pnpm's own container image installs, and verified against a checksum committed to this repository
(`pnpm/pnpm-amd64.sha256`, `pnpm/pnpm-arm64.sha256`).

pnpm publishes neither a checksum nor a detached signature, so that checksum is not fetched from
upstream — it is derived here, and only from an archive whose origin has been established.
`.github/workflows/update-material.yml` runs `pnpm/checksum.sh` whenever the pinned version changes,
and the script records a digest only after `gh attestation verify` has confirmed that the archive's
[build provenance](https://github.com/pnpm/pnpm/blob/main/.github/workflows/release.yml) was signed
by pnpm's release workflow at that version's tag. The resulting checksum is committed and reviewed
like any other change, so what the image build trusts is a digest this repository accepted, rather
than one the release host served alongside the archive.

Note that this covers the pnpm binary only. Runtimes and packages that pnpm installs at runtime are
fetched from their own upstreams under pnpm's own verification, outside this image's build pipeline.
