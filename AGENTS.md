# Repository Guidelines

This repository builds and publishes minimal Debian-based Docker images for use as dev containers, published to `ghcr.io/bare-devcontainer/<image>`.

```
<image>/
  Dockerfile    # image build instructions
  build.yaml    # image description and variant definitions: tags, build args, debian_variant
  README.md     # image docs; the Tags table between <!-- tags:begin/end --> markers is generated
build-config.sh              # CLI for querying build.yaml; used by CI to generate matrices and build args
update-readme.sh             # regenerates the README Tags tables from build.yaml; run by CI after each release
.github/workflows/
  release.yml                # builds and pushes images to GHCR
.devcontainer/
  default/                   # dev container for working in this repo
  sandbox-<image>/           # one per image; for manually testing each published image
renovate.json                # Renovate config
```

- Images are organized in two layers:
  - base image(`debian`); all other images extend it
  - language-specific images built on the debian base
- All images are built on Debian base images, and target multi-arch (linux/amd64 + linux/arm64) builds.
- Use English for all documentation and comments.
- PR titles must follow Conventional Commits format:
  - Allowed types: `image`, `ci`, `chore`, `test`, `docs`
  - The scope is optional. Examples:
    - `image(python): add Python 3.13 variant`
    - `ci: pin action SHAs`
    - `chore: update renovate config`
