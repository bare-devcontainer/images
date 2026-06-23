# Repository Guidelines

This repository builds and publishes minimal Debian-based Docker images for use as dev containers, published to `ghcr.io/bare-devcontainer/<image>`.

```
<image>/
  Dockerfile    # image build instructions
  build.yaml    # variant definitions: tags, build args, debian_variant
build-config.sh              # CLI for querying build.yaml; used by CI to generate matrices and build args
.github/workflows/
  publish.yml                # builds and pushes images to GHCR
  lint.yml                   # runs various linters
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
