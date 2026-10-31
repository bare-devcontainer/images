# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# check=error=true

FROM ghcr.io/bare-devcontainer/debian:trixie-20261031@sha256:b2800b06ff61cc450f4a6fff97ccb412d70bcd75d6c452f93998d6ed8f05f412

USER root

# Enable debian backports for `yq-go`.
COPY ./debian-backports.sources /etc/apt/sources.list.d/

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    export DEBIAN_FRONTEND=noninteractive \
      && apt-get update \
      && apt-get --no-install-recommends install -y skopeo yq-go

USER dev

