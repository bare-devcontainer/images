# Repository Guidelines

This repository builds and publishes minimal Debian-based Docker images for use as dev containers, published to `ghcr.io/bare-devcontainer/<image>`.

```
<image>/
  Dockerfile    # image build instructions
  build.yaml    # image description, variant definitions (tags, build args, debian_variant), and trusted material sources (materials)
  README.md     # image docs; the Tags table between <!-- tags:begin/end --> markers is generated
scripts/                     # CLI helpers CI calls; each script's header comment documents it
.github/workflows/
  release.yml                # builds and pushes images to GHCR
  mirror.yml                 # copies published images from GHCR to Docker Hub and sets the description of each Docker Hub repository; called by release.yml, or run by hand for a full sync
  build-checks.yml           # for each changed image: builds it on the debian base built from the same checkout when the checkout's debian/ differs from the published base (changed in the pull request, or on main since the last release) and on the published one otherwise, smoke-tests it, builds its sandbox dev container, and runs the Dev Container Feature tests on the base
  trivyignore-cleanup.yml    # scans the published images with no ignore file in play and opens a pull request removing the .trivyignore.yaml entries left without a finding
.devcontainer/
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
- GHCR is where every image is published; Docker Hub is a mirror of it. `mirror.yml` copies manifests unchanged, so a tag resolves to the same digest on both registries. A release mirrors the tags `build.yaml` names for each image together with the dated tags of that release, and regsync copies the ones the source registry holds, so an image the release left alone contributes no dated tag while its other tags resolve to the digests already published; the tags of earlier releases and of variants `build.yaml` no longer defines are picked up by running `mirror.yml` by hand with `full` set, which enumerates the source registry instead. The same workflow sets what each Docker Hub repository says about itself: the short description is the `description` of `build.yaml`, and the overview is `dockerhub-overview.sh`'s rendering of `<image>/README.md`, so the README stays the one place the image is documented. Docker Hub renders neither the relative links nor the alert syntax a README may use, so anything the rendering cannot carry over fails the workflow rather than reaching the page.
- Each image README is also shown on its own, as the Docker Hub overview, so it has to make the case for the image without the root README around it: it opens with the shared statement of what the images are built for and ends with the shared `Verifying the image` section. Keep that wording alike across images, and keep the root README the place the details live; the image README links there and to its own `Supply chain` section.
- Dev Container Feature checks exist to guarantee that Features can supply tooling the images deliberately omit. When adding one:
  - Cover a Feature when it exercises an install mechanism that no already-covered Feature exercises (user and shell provisioning, a third-party apt repository, a release binary download, an upstream install script). Do not add a second Feature that only repeats a covered mechanism.
  - Cover a Feature only when it complements the images by supplying something they do not provide. A Feature that would replace what an image already ships is out of scope.
  - Verify against `debian` alone, since every image extends it. Add the Feature to the single `.devcontainer/feature-debian` configuration rather than introducing another one.
  - Leave Feature options at their upstream defaults, so the check reflects what a consumer gets. Record the reason in a comment whenever a default has to be overridden.
  - Assert only what the Feature and the image are jointly responsible for. The container's runtime flags are Docker's behaviour, not this repository's, so leave them unasserted; the image's own `smoke-test.sh` runs first and covers what the image ships, so never repeat it in `test.sh`.
- Scheduled workflows, all UTC. Keep a new one off the daily release run at 00:00, and off Monday, which the weekly rebuild and the three checks that read published images already share:

  | Workflow | Schedule | Runs |
  |----------|----------|------|
  | `release.yml` | daily 00:00 | publishes the images whose own files, or the `debian` base every image extends, changed since the last release, plus one rebuild of every image every Monday |
  | `trivy.yml` | Monday 06:00 | scans the published images |
  | `trivyignore-cleanup.yml` | Monday 07:00 | opens a pull request dropping `.trivyignore.yaml` entries left without a finding |
  | `attest-check.yml` | Monday 08:00 | verifies the attestations of the published images |
  | `update-material.yml` | Wednesday 06:00 | opens a pull request refreshing the trust material |
  | `update-zig-master.yml` | daily 05:00 | opens a pull request moving the Zig master pin |

  Every version an automation moves arrives as a pull request, so `build-checks.yml` builds it before it can be merged and an upstream that breaks simply stays unmerged.
- A release rebuilds an image when a file in its directory or in `debian/` changed since the last release tag, judged by `scripts/changed-images.sh`. A change outside the image directories (a workflow, a shared script) reaches the published images with the Monday rebuild, or sooner by running `release.yml` by hand with `force` set.
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
- Comments are one of two kinds:
  - Documentation comments: the purpose of a file, function, or block, written at the top of it.
  - Inline comments: one of exactly three things — a behaviour of an external system, a coupling to another file, or a constraint a plausible edit would silently break. Anything else: delete it.
- Comments describe the code as it is, never how it came to be. A decision, an alternative, a past incident, or an answer to review feedback is how it came to be, and belongs in the commit message and the pull request.
- Default to no comment. Re-read every comment you added or reworded before committing.
- Sign every commit with the signing key the environment configures, and commit under the identity that key belongs to. Never pass another user's name or email to `git commit`: a commit whose author does not match the signing key goes out unsigned and GitHub cannot verify it.
- PR titles must follow Conventional Commits format:
  - Allowed types: `image`, `ci`, `chore`, `test`, `docs`
  - The scope is optional. Examples:
    - `image(python): add Python 3.13 variant`
    - `ci: pin action SHAs`
    - `chore: update renovate config`
