ARG DEBIAN_TAG
FROM debian:${DEBIAN_TAG}

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
ARG INSTALL_SUDO=false

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
        && export DEBIAN_FRONTEND=noninteractive \
        && apt update \
        && apt-get --no-install-recommends install -y \
                # Git essentials
                git openssh-client gnupg2 \
                # Network utilities
                ca-certificates iproute2 curl wget \
                # System moniroting utitilities
                procps lsof psmisc \
                # Archive utilities
                unzip bzip2 xz-utils zip zlib1g \
                # File utilities
                less jq \
                # Misc
                bash-completion lsb-release locales man-db manpages \
        && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen \
        && groupadd --gid ${USER_GID} ${USERNAME} \
        && useradd -m -s /bin/bash -u ${USER_UID} -g ${USER_GID} ${USERNAME} \
        && if [ "${INSTALL_SUDO}" = "true" ]; then \
                apt-get install -y --no-install-recommends sudo \
                && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
                && chmod 0440 /etc/sudoers.d/${USERNAME}; \
                fi

USER dev
WORKDIR /workspace
