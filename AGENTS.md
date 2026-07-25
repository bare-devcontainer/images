# Repository Guidelines

This repository builds and publishes minimal Debian-based Docker images for use as dev containers, published to `ghcr.io/bare-devcontainer/<image>`.

```
<image>/
  Dockerfile    # image build instructions
  build.yaml    # image description, variant definitions (tags, build args, debian_variant), and trusted material sources (materials)
  README.md     # image docs; the Tags table between <!-- tags:begin/end --> markers is generated
scripts/
  build-config.sh            # CLI for querying build.yaml; used by CI to generate matrices and build args
  changed-images.sh          # maps changed files to the images they affect; used by build-checks.yml to skip untouched images
  update-material.sh         # refreshes the trust material declared in build.yaml (materials); called by update-material.yml
  update-readme.sh           # regenerates the README Tags tables from build.yaml; run by CI after each release
  verify-image.sh            # confirms image verification steps succeed for a published image; run by attest-check.yml
.github/workflows/
  release.yml                # builds and pushes images to GHCR
  build-checks.yml           # for each changed image: builds and smoke-tests it, builds its sandbox dev container, and runs the Dev Container Feature tests on the base
.devcontainer/
  default/                   # dev container for working in this repo
  sandbox-<image>/           # one per image; for manually testing each published image. Kept free of Features so it mirrors the published image
  feature-<image>/           # an image with every verified Dev Container Feature layered on, plus the test.sh covering them
renovate.jsonc               # Renovate config
```

- Images are organized in two layers:
  - base image(`debian`); all other images extend it
  - language-specific images built on the debian base
- All images are built on Debian base images, and target multi-arch (linux/amd64 + linux/arm64) builds.
- Dev Container Feature checks exist to guarantee that Features can supply tooling the images deliberately omit. When adding one:
  - Cover a Feature when it exercises an install mechanism that no already-covered Feature exercises (user and shell provisioning, a third-party apt repository, a release binary download, an upstream install script). Do not add a second Feature that only repeats a covered mechanism.
  - Cover a Feature only when it complements the images by supplying something they do not provide. A Feature that would replace what an image already ships is out of scope.
  - Verify against `debian` alone, since every image extends it. Add the Feature to the single `.devcontainer/feature-debian` configuration rather than introducing another one.
  - Leave Feature options at their upstream defaults, so the check reflects what a consumer gets. Record the reason in a comment whenever a default has to be overridden.
  - Assert only what the Feature and the image are jointly responsible for. The container's runtime flags are Docker's behaviour, not this repository's, so leave them unasserted; the image's own `smoke-test.sh` runs first and covers what the image ships, so never repeat it in `test.sh`.
- Use English for all documentation and comments.
- Comments should follow either of the following types:
  - Documentation comments: describe the purpose/signature of a file, function, or block of code. 
  - Inline comments: describe the important details of a line or block of code for future maintainers. Avoid obvious comments, or comments only useful in the context of the current change. 
- PR titles must follow Conventional Commits format:
  - Allowed types: `image`, `ci`, `chore`, `test`, `docs`
  - The scope is optional. Examples:
    - `image(python): add Python 3.13 variant`
    - `ci: pin action SHAs`
    - `chore: update renovate config`
