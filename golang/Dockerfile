ARG GOLANG_TAG
ARG DEBIAN_TAG

FROM golang:${GOLANG_TAG} AS golang

FROM ghcr.io/bare-devcontainer/debian:${DEBIAN_TAG}

USER root

COPY --from=golang /usr/local/go /usr/local/go

ENV GOPATH=/home/dev/go
ENV PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}

RUN install -d -o dev -g dev \
    "${GOPATH}" \
    "${GOPATH}/pkg/mod" \
    /home/dev/.cache/go-build

USER dev
WORKDIR /workspaces
