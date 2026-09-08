# temurin

Dev container image for Java development, with the [Eclipse Temurin](https://adoptium.net/temurin/)
JDK installed, built on the [debian](../debian) base image.

Like every image in this repository, it is minimal, built only from upstreams verified at build
time, and published with SLSA provenance, a GitHub artifact attestation, and an SBOM; it runs as
the non-root user `dev`. [Why these images](../README.md#why-these-images) explains the
reasoning, and [Verifying the image](#verifying-the-image) below shows how to check a build.

## Image

```
ghcr.io/bare-devcontainer/temurin:<tag>
```

Reference it from `.devcontainer/devcontainer.json`, pinning the digest as well as the tag:

```json
{
  "image": "ghcr.io/bare-devcontainer/temurin:21@sha256:<digest>"
}
```

## Dev Container Template

A ready-to-use Dev Container template for this image is available at
[bare-devcontainer/templates](https://github.com/bare-devcontainer/templates/tree/main/src/temurin).
It provides the recommended configuration for this image, including security hardening and
volume mounts that persist cache directories for faster rebuilds.

## Tags

<!-- tags:begin -->
| Tags | Debian variant |
|------|----------------|
| `25.0.4.1-trixie`, `25-trixie`, `trixie`, `25.0.4.1`, `25` | trixie |
| `25.0.4.1-bookworm`, `25-bookworm`, `bookworm` | bookworm |
| `21.0.12.1-trixie`, `21-trixie`, `21.0.12.1`, `21` | trixie |
| `21.0.12.1-bookworm`, `21-bookworm` | bookworm |

Tags are also published with a date suffix on each build (e.g., `25.0.4.1-trixie-<YYYYMMDD>`).
<!-- tags:end -->

The version in these tags is the version of the JDK, as Temurin numbers its releases
(`21.0.12.1` is the JDK 21.0.12.1 release); the build number is not part of the tag.

## Installed software

Everything from the [debian](../debian) base image, plus:

- [Eclipse Temurin JDK](https://adoptium.net/temurin/) (`java`, `javac`, `jar`, `jshell`,
  `keytool`, and the other JDK tools), one feature release per tag

`JAVA_HOME` points at the JDK, and its tools are on `PATH` through Debian's alternatives
system. The JDK's trust store is the system CA store, kept in step by `adoptium-ca-certificates`,
so certificates added with `update-ca-certificates` are trusted by Java as well.

`~/.m2/repository` and `~/.gradle` exist and are owned by `dev`, so a volume mounted on either
keeps the Maven or Gradle cache across container rebuilds.

## Not installed

- **No Maven or Gradle.** A project's `mvnw` or `gradlew` wrapper downloads the version the
  project pins, so the image adds nothing that could disagree with it. Add a Dev Container
  Feature or your own `Dockerfile` for a project without a wrapper.
- **No language server.** The Java extensions of VS Code and the JetBrains IDEs bring their own,
  and only need the JDK this image provides.
- **No second JDK.** One feature release is installed per tag. The Adoptium apt repository stays
  configured, so a `Dockerfile` built on this image can `apt-get install temurin-17-jdk` next to
  it; `update-alternatives --config java` then switches between them.

Unlike the version-manager images, the JDK here is fixed by the image tag. A project that
requires a newer feature release than the tag provides needs the matching tag rather than a
download at runtime.

## Supply chain

The JDK is installed with `apt` from the
[Adoptium package repository](https://packages.adoptium.net/), the channel Adoptium documents
for Debian, pinned in `build.yaml` to an exact package version. `apt` verifies the repository
index against Adoptium's signing key on every install, and the key
(`temurin/adoptium-signing-key.asc`) is committed to this repository, so the index is checked
against a key reviewed here rather than one fetched at build time.

## Verifying the image

Every build is published with SLSA provenance, a GitHub artifact attestation, and an SBOM. The
attestation confirms that an image was built by the release workflow of this repository and has
not been altered since:

```sh
gh attestation verify oci://ghcr.io/bare-devcontainer/temurin:<tag>@sha256:<digest> \
  --owner bare-devcontainer
```

The attestation is looked up by digest, and the Docker Hub mirror carries the same digests, so
an image pulled from `docker.io/baredevcontainer/temurin` verifies with the same command against
its own reference. [Verifying Published Images](../README.md#verifying-published-images) covers
inspecting the provenance and the SBOM as well.
