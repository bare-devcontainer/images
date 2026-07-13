# debian

Minimal Debian base image for dev containers. All other images in this repository extend this image.

## Image

```
ghcr.io/bare-devcontainer/debian:<tag>
```

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `trixie` | trixie |
| `bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `trixie-<YYYYMMDD>`).
<!-- tags:end -->

## Installed software

- **Git & SSH**: `git`, `openssh-client`, `gnupg2`
- **Network**: `ca-certificates`, `iproute2`, `curl`, `wget`
- **System utilities**: `procps`, `lsof`, `psmisc`
- **Archive utilities**: `unzip`, `bzip2`, `xz-utils`, `zip`, `zlib1g`
- **File utilities**: `less`, `jq`, `vim.tiny`
- **Misc**: `bash-completion`, `lsb-release`, `locales` (en_US.UTF-8), `man-db`, `manpages`
