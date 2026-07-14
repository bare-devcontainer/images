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
- Remove `/etc/apt/apt.conf.d/docker-clean` only in the debian base image. Images built on the base inherit its filesystem, so re-removing it is redundant.
- Set `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` at the top of every stage that runs non-trivial `RUN` commands (network fetches, verification, apt), so pipes added later fail safely by default.
- Restate `USER dev` only in stages that previously switched to `USER root`. Never restate `WORKDIR /workspaces`; it is inherited from the base image config.

For example:

```dockerfile
FROM debian:trixie-20260713@sha256:fac46bff2e02f51425b6e33b0e1169f55dfb053d83511ca28aa50c09fd5ed7a4

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
