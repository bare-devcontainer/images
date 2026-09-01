# Repository Guidelines

This repository builds and publishes minimal Debian-based Docker images for use as dev containers, published to `ghcr.io/bare-devcontainer/<image>`.

```
<image>/                     # one per image: its Dockerfile, smoke test, build.yaml (variants: tags, build args, debian_variant; and materials), and README, whose Tags table between the <!-- tags:begin/end --> markers is generated
scripts/                     # CLI helpers CI calls; each script's header comment documents it
.github/workflows/           # build, release, scanning and housekeeping automation
.devcontainer/               # dev container configurations, one per purpose below
  default/                   # dev container for working in this repo
  sandbox-<image>/           # one per image; for manually testing each image. Kept free of Features so it mirrors the published image
  feature-<image>/           # an image with every verified Dev Container Feature layered on, plus the test.sh covering them
renovate.jsonc               # Renovate config
.trivyignore.yaml            # Trivy findings waived until upstream ships a fix
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
- `.trivyignore.yaml` is the only place a `CRITICAL`/`HIGH` finding is waived, so an entry is a statement that the image cannot currently do anything about the finding. When a scan fails:
  - Check the latest upstream release of the affected component first. A finding that release already fixes is resolved by taking it — bump the pinned version in `build.yaml`, or let the Renovate pull request do it — and gets no entry.
  - Only a finding whose newest upstream release is still affected is ignored. Record in `statement` what was checked and nothing else: the dependency (or Go toolchain) version the pinned release carries, the version the fix is in, and what upstream carries on the branch the next release comes from. The `id` is the reference for what the finding is, so never restate the advisory.
  - List the binaries actually reported in `paths`, rather than suppressing the id image-wide, so an entry stops covering a binary as soon as upstream fixes that one.
  - Set `expired_at` to when the upstream fix is expected, judged from where the fix sits upstream and the component's release cadence. When that cannot be estimated — upstream carries no fix yet — set a date to re-check by instead, at most three months out. An entry covering several binaries takes the earliest of their dates, so the expiry re-opens the review for all of them.
  - `trivyignore-cleanup.yml` drops entries and paths that no longer suppress anything, but it deliberately leaves expired entries in place: an expired entry fails the scan again, and extending it is a judgement call that belongs to a reviewer who re-checks upstream.
- The sandbox dev containers take their build args from the environment with no defaults, so `build-checks.yml` can build them with the arguments it just built the image with and reuse those layers. Export the arguments of the variant you want before opening one by hand:

  ```sh
  set -a
  . <(scripts/build-config.sh build-args node 26-trixie)
  DEBIAN_TAG=$(scripts/build-config.sh get-field node 26-trixie debian_variant)
  set +a
  code .
  ```

  `debian` is the exception: its `build-args` already carry `DEBIAN_TAG`, so the second line is unnecessary.
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
