# Repository Guidelines

This repository builds and publishes minimal Debian-based Docker images for use as dev containers, published to `ghcr.io/bare-devcontainer/<image>`.

```
<image>/
  Dockerfile    # image build instructions
  build.yaml    # image description, variant definitions (tags, build args, debian_variant), and trusted material sources (materials)
  README.md     # image docs; the Tags table between <!-- tags:begin/end --> markers is generated
scripts/                     # CLI helpers CI calls; each script's header comment documents it
.github/workflows/
  release.yml                # builds and pushes images to GHCR, then tags the release and publishes a GitHub Release whose notes list the images it rebuilt
  mirror.yml                 # copies published images from GHCR to Docker Hub and sets the description of each Docker Hub repository; called by release.yml, or run by hand for a full sync
  build-checks.yml           # for each changed image: builds it on the debian base built from the same checkout when the checkout's debian/ differs from the published base (changed in the pull request, or on main since the last release) and on the published one otherwise, verifies it as a dev container and smoke-tests it there, and runs the Dev Container Feature tests on the base
  trivyignore-cleanup.yml    # scans the published images with no ignore file in play and opens a pull request removing the .trivyignore.yaml entries left without a finding
.devcontainer/               # dev container for working in this repo
tests/                       # dev container checks; each names the image under test through ${localEnv:IMAGE_REF}
  image/                     # the image on its own, kept free of Features so it mirrors what a consumer references, plus the test.sh covering what its devcontainer.metadata label supplies
  features/                  # the image with every verified Dev Container Feature layered on, plus the test.sh covering them
renovate.jsonc               # Renovate config
.trivyignore.yaml            # Trivy findings waived until upstream ships a fix
```

- Images are organized in two layers:
  - base image(`debian`); all other images extend it
  - language-specific images built on the debian base
- All images are built on Debian base images, and target multi-arch (linux/amd64 + linux/arm64) builds.
- Every image runs as the non-root user `dev` and ships nothing `dev` owns outside `/home/dev`, so a client's `updateRemoteUserUID` remap, which re-owns the home directory alone, leaves nothing behind, and no code the container runs can modify the toolchain. `scripts/check-image-ownership.sh` asserts it in `build-checks.yml`. In a Dockerfile:
  - Extract an upstream archive with `tar --no-same-owner`; root tar restores the uid it records, and some upstreams build theirs as uid 1000.
  - Create a directory before the `USER` instruction that switches to `dev`, as `/workspaces` is in the base image.
  - Own a directory `dev` writes to outside its home as `root:<group>` with `chmod 2775`, with `dev` in the group. Group membership survives the remap, user ownership does not.
- No environment variable an image sets points at a directory `dev` can write. `ENV` applies to every user in the container, so such a variable would let anything the container runs shadow a command another user resolves, or redirect where another user's tool reads and writes. Declare it through `remoteEnv` in the `devcontainer.metadata` label instead, which only a Dev Container client's own processes pick up, with `${containerEnv:NAME}` carrying the image's own value over where the variable extends one, as `PATH` does. A re-declared label replaces, rather than merges with, the one inherited from the base image, so repeat everything that label declares. In `build-checks.yml`, `scripts/check-image-env.sh` asserts the rule against the built image, and `tests/image/test.sh` holds a client to applying the label, the entries the base image declares included, which is also why the image's `smoke-test.sh` runs in that dev container: the tools it reaches for are on the `PATH` a client assembles, not the image's own.
- GHCR is where every image is published; Docker Hub is a mirror of it. `mirror.yml` copies manifests unchanged, so a tag resolves to the same digest on both registries. A release mirrors the tags `build.yaml` names for each image together with the dated tags of that release, and regsync copies the ones the source registry holds, so an image the release left alone contributes no dated tag while its other tags resolve to the digests already published; the tags of earlier releases and of variants `build.yaml` no longer defines are picked up by running `mirror.yml` by hand with `full` set, which enumerates the source registry instead. The same workflow sets what each Docker Hub repository says about itself: the short description is the `description` of `build.yaml`, and the overview is `dockerhub-overview.sh`'s rendering of `<image>/README.md`, so the README stays the one place the image is documented. Docker Hub renders neither the relative links nor the alert syntax a README may use, so anything the rendering cannot carry over fails the workflow rather than reaching the page.
- Each image README is also shown on its own, as the Docker Hub overview, so it has to make the case for the image without the root README around it: it opens with the shared statement of what the images are built for and ends with the shared `Verifying the image` section. Keep that wording alike across images, and keep the root README the place the details live; the image README links there and to its own `Supply chain` section.
- Dev Container Feature checks exist to guarantee that Features can supply tooling the images deliberately omit. When adding one:
  - Cover a Feature when it exercises an install mechanism that no already-covered Feature exercises (user and shell provisioning, a third-party apt repository, a release binary download, an upstream install script). Do not add a second Feature that only repeats a covered mechanism.
  - Cover a Feature only when it complements the images by supplying something they do not provide. A Feature that would replace what an image already ships is out of scope.
  - Verify against `debian` alone, since every image extends it. Add the Feature to the single `tests/features` configuration rather than introducing another one.
  - Leave Feature options at their upstream defaults, so the check reflects what a consumer gets. Record the reason in a comment whenever a default has to be overridden.
  - Assert only what the Feature and the image are jointly responsible for. The container's runtime flags are Docker's behaviour, not this repository's, so leave them unasserted; the image's own `smoke-test.sh` runs first and covers what the image ships, so never repeat it in `test.sh`.
- Scheduled workflows, all UTC. Keep a new one off the daily release run at 00:00, and off Monday, which the weekly rebuild and the three checks that read published images already share:

  | Workflow | Schedule | Runs |
  |----------|----------|------|
  | `release.yml` | daily 00:00 | publishes the variants whose own definition, or the `debian` variant they are built FROM, changed since the last release, plus one rebuild of every variant every Monday |
  | `trivy.yml` | Monday 06:00 | scans the published images |
  | `trivyignore-cleanup.yml` | Monday 07:00 | opens a pull request dropping `.trivyignore.yaml` entries left without a finding |
  | `attest-check.yml` | Monday 08:00 | verifies the attestations of the published images |
  | `update-material.yml` | Wednesday 06:00 | opens a pull request refreshing the trust material |
  | `update-zig-master.yml` | daily 05:00 | opens a pull request moving the Zig master pin |

  Every version an automation moves arrives as a pull request, so `build-checks.yml` builds it before it can be merged and an upstream that breaks simply stays unmerged.
- A release publishes single variants, not whole images, judged by `scripts/changed-variants.sh`: a file other than `build.yaml` under an image directory rebuilds every variant of that image, since they share it, while a `build.yaml` change rebuilds the variants whose entry differs from the one the last release tag holds, or every variant of the image when what changed sits outside `variants`, and a rebuilt `debian` variant rebuilds the variants naming it in `debian_variant`. So a Renovate pull request that moves one pinned version, or the `debian` digest of one suite, leaves the rest of the published tags where they are. A change outside the image directories (a workflow, a shared script) reaches the published images with the Monday rebuild, or sooner by running `release.yml` by hand with `force` set. `build-checks.yml` stays at image granularity, by `scripts/changed-images.sh`, so every variant of a changed image is built before the change can merge.
- `.trivyignore.yaml` is the only place a `CRITICAL`/`HIGH` finding is waived, so an entry is a statement that the image cannot currently do anything about the finding. When a scan fails:
  - Check the latest upstream release of the affected component first. A finding that release already fixes is resolved by taking it — bump the pinned version in `build.yaml`, or let the Renovate pull request do it — and gets no entry.
  - Only a finding whose newest upstream release is still affected is ignored. Record in `statement` what was checked and nothing else: the dependency (or Go toolchain) version the pinned release carries, the version the fix is in, and what upstream carries on the branch the next release comes from. The `id` is the reference for what the finding is, so never restate the advisory.
  - List the binaries actually reported in `paths`, rather than suppressing the id image-wide, so an entry stops covering a binary as soon as upstream fixes that one. A Debian package finding carries no path, so scope it with `purls` instead, as `pkg:deb/debian/<package>` with no suite, which covers every variant in one entry.
  - Set `expired_at` to when the upstream fix is expected, judged from where the fix sits upstream and the component's release cadence. When that cannot be estimated — upstream carries no fix yet — set a date to re-check by instead, at most three months out. An entry covering several binaries takes the earliest of their dates, so the expiry re-opens the review for all of them.
  - `trivyignore-cleanup.yml` drops entries and paths that no longer suppress anything, but it deliberately leaves expired entries in place: an expired entry fails the scan again, and extending it is a judgement call that belongs to a reviewer who re-checks upstream.
- The dev container checks under `tests/` reference an image rather than building a Dockerfile, so that they verify what a consumer's client reads. For a `build` configuration the Dev Container CLI takes the `devcontainer.metadata` label off the base image the Dockerfile names — the plain Debian image, which carries none — and the label the images declare is never applied, so a check built that way proves nothing about what is published. The image is named through `${localEnv:IMAGE_REF}`, read with no default so a run never silently verifies another image; `build-checks.yml` passes the image it just built. Export the image you want before running one by hand:

  ```sh
  export IMAGE_REF=ghcr.io/bare-devcontainer/node:26-trixie
  devcontainer up --workspace-folder . --config tests/image/devcontainer.json
  devcontainer exec --workspace-folder . --config tests/image/devcontainer.json bash tests/image/test.sh
  ```
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
