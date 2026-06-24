---
description: Dockerfile guidelines for the project.
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
---

## Dockerfile Guidelines

- Always pin base images to both a tag and a SHA256 digest. Never use `latest` or a tag alone.
- Combine related commands into a single `RUN` statement to minimize the number of layers.
- Use BuildKit cache mounts to speed up builds without bloating image layers.
- Create a non-root user and switch to it at the end of the Dockerfile.

For example:

```dockerfile
FROM debian:trixie-20260623@sha256:d07d1b51c39f51188e60be9b64e6bf769fa94e187f092bc32b91305cfa34ba5a

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
