# Bare Dev Container Images

## General Guidelines

- Use English for all documentation and comments.

## Dockerfile Guidelines

- Pin image digests: Always pin base images to both a tag and a SHA256 digest. Never use `latest` or a tag alone.
- Avoid unnecessary layers: Combine related commands into a single `RUN` statement to minimize the number of layers.
- Avoid unnecessary copy: Use BuildKit cache mounts to speed up builds without bloating image layers. 
- Avoid root user: Create a non-root user and switch to it at the end of the Dockerfile.

For example:

```dockerfile
FROM debian:trixie-20260518@sha256:4ae67669760b807c19f23902a3fd7c121a6a70cf2ae709035674b23e712e4d62

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get --no-install-recommends install -y ca-certificates

RUN groupadd --gid 1000 nonroot \
    && useradd -m -s /bin/bash -u 1000 -g 1000 nonroot

USER nonroot
WORKDIR /workspaces
```

## GitHub Actions Guidelines

- Principle of Least Privilege: Deny all permissions at the workflow level and only grant permissions that are necessary for each job.
- Set `timeout-minutes` on every job to prevent runaway builds from consuming resources.
- Commit SHA Pinning: Every `uses:` reference must be pinned to a full commit SHA, with the version tag as a comment.
- Always set `persist-credentials: false` on `actions/checkout` to prevent the GITHUB_TOKEN from being available to subsequent steps unintentionally:

For example:

```yaml
permissions: {}   # deny everything by default

jobs:
  build:
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha> # v6.0.3
        with:
          persist-credentials: false
```
