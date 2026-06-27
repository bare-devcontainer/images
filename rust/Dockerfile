ARG DEBIAN_TAG

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

USER root

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
        && export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y rustup

ENV PATH=/home/dev/.cargo/bin:${PATH}

RUN install -d -o dev -g dev \
    /home/dev/.cargo \
    /home/dev/.cargo/registry \
    /home/dev/.cargo/git

USER dev
WORKDIR /workspaces
