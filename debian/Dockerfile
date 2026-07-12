# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# check=skip=InvalidDefaultArgInFrom;error=true
# ARGs are intentionally required to prevent accidental builds with the wrong base image.

ARG DEBIAN_TAG
FROM debian:${DEBIAN_TAG}

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Dev Container metadata (https://containers.dev/implementors/reference/#labels),
# applied automatically by Dev Container clients when this image is referenced.
# Inherited by every image built FROM this one; re-declaring this label in a
# child image replaces (does not merge with) this value.
LABEL devcontainer.metadata="[{\"remoteUser\":\"dev\",\"containerUser\":\"dev\"}]"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
        && export DEBIAN_FRONTEND=noninteractive \
        && apt-get update \
        && apt-get --no-install-recommends install -y \
                # Git essentials
                git openssh-client gnupg2 \
                # Scripting
                python3 \
                # Network utilities
                ca-certificates iproute2 curl wget \
                # System monitoring utilities
                procps lsof psmisc \
                # Archive utilities
                unzip bzip2 xz-utils zip zlib1g \
                # File utilities
                less jq vim-tiny \
                # Misc
                bash-completion lsb-release locales man-db manpages \
        && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen \
        && groupadd --gid "${USER_GID}" "${USERNAME}" \
        && useradd -l -m -s /bin/bash -u "${USER_UID}" -g "${USER_GID}" "${USERNAME}"

COPY --chown=${USERNAME}:${USERNAME} assets/.bashrc /home/${USERNAME}/.bashrc

USER ${USERNAME}
WORKDIR /workspaces
