# Contributing

Bug reports, image requests, and pull requests are welcome.

## Repository layout

```
<image>/
  Dockerfile      # image build instructions
  build.yaml      # description, variant definitions (tags, build args, debian_variant),
                  # and trusted material sources (materials)
  README.md       # image docs; the Tags table between <!-- tags:begin/end --> is generated
  smoke-test.sh   # runs inside the built image in CI
scripts/          # helpers used by CI; see AGENTS.md for what each one does
.github/workflows/
.devcontainer/
  default/            # dev container for working in this repo
  sandbox-<image>/    # one per image, for testing it by hand
  feature-debian/     # the base plus every verified Dev Container Feature
```

Images are organized in two layers: the `debian` base, and the language-specific images that
extend it. All of them target `linux/amd64` and `linux/arm64`.

[AGENTS.md](AGENTS.md) documents the conventions in more detail — how images are structured,
when a new Dev Container Feature check is worth adding, and how the sandbox dev containers take
their build arguments. It is worth reading before a first change.

## Working on an image

The repository has a dev container of its own (`.devcontainer/default`), which brings the
tooling the scripts need.

Query `build.yaml` through `scripts/build-config.sh` rather than parsing it directly. Variant
names are the ones declared in `build.yaml`, not tags — `scripts/build-config.sh variants
<image>` lists them:

```sh
scripts/build-config.sh variants node                              # ["26-trixie", ...]
scripts/build-config.sh build-args node 26-trixie                  # KEY=VALUE per line
scripts/build-config.sh get-field node 26-trixie debian_variant
```

To build and test an image the way CI does, export the variant's build arguments and pass them
through:

```sh
IMAGE=node VARIANT=26-trixie

set -a
. <(scripts/build-config.sh build-args "$IMAGE" "$VARIANT")
DEBIAN_TAG=$(scripts/build-config.sh get-field "$IMAGE" "$VARIANT" debian_variant)
set +a

BUILD_ARGS=()
while IFS='=' read -r key _; do BUILD_ARGS+=(--build-arg "$key"); done \
  < <(scripts/build-config.sh build-args "$IMAGE" "$VARIANT")

docker build "$IMAGE" "${BUILD_ARGS[@]}" --build-arg DEBIAN_TAG -t "$IMAGE:dev"
docker run --rm -v "$PWD/$IMAGE/smoke-test.sh:/smoke-test.sh:ro" "$IMAGE:dev" bash /smoke-test.sh
```

`debian` is the exception: its `build-args` already carry `DEBIAN_TAG`, so the `get-field` line
is unnecessary there.

To try an image interactively instead, open the matching `.devcontainer/sandbox-<image>` with
the same environment variables exported — the sandbox configurations read their build arguments
from the environment with no defaults, so a missing value fails the build rather than silently
selecting a different version.

## Changing tags or versions

`build.yaml` is the single source of truth for an image's tags and build arguments. After
editing it, regenerate the README tables:

```sh
scripts/update-readme.sh <image>
```

The `Tags` section of each image README lies between `<!-- tags:begin -->` and
`<!-- tags:end -->` and is overwritten by that script — edit `build.yaml` instead. Everything
outside the markers is written by hand.

Version bumps for pinned upstreams are normally raised by Renovate. When a pinned version
changes, the checksums and keys declared under `materials` in `build.yaml` are refreshed by
`.github/workflows/update-material.yml`, which pushes them onto the same pull request so they
are reviewed together with the version change.

## Checks

Pull requests run:

- **Lint** — hadolint on Dockerfiles, shellcheck on shell scripts, and `decolint` on
  `devcontainer.json` files.
- **Build Checks** — for each changed image, a build, its `smoke-test.sh`, a Trivy scan, the
  sandbox dev container build, and the Dev Container Feature tests on the base.
- **PR Title Check** — see below.

Lint and shellcheck are worth running locally before pushing; the build checks need Docker and
are usually easier to leave to CI.

## Pull request titles

Titles must follow [Conventional Commits](https://www.conventionalcommits.org/), with one of
these types (the scope is optional):

| Type | Use for |
|------|---------|
| `image` | Changes to an image's contents or build |
| `ci` | Workflows and CI configuration |
| `chore` | Dependency and repository maintenance |
| `test` | Smoke tests and Feature tests |
| `docs` | Documentation |

Examples:

```
image(python): add Python 3.13 variant
ci: pin action SHAs
chore: update renovate config
```

## Documentation conventions

- Write documentation and comments in English.
- Comments are either documentation comments, describing the purpose of a file or block, or
  inline comments, explaining a detail a future maintainer would need. Avoid comments that
  restate the code or that only make sense while reviewing the current change.

## Security

To report a vulnerability, see [SECURITY.md](SECURITY.md). Please do not open a public issue
for one.
