# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base image: Bluefin DX. Everything Bluefin ships (VS Code, Docker, Homebrew,
# Bazaar, ujust, uupd, codecs, ...) comes from here; build.sh adds COSMIC.
# NVIDIA GPU? Use ghcr.io/ublue-os/bluefin-dx-nvidia-open:stable instead.
FROM ghcr.io/ublue-os/bluefin-dx:stable

### MODIFICATIONS
## Everything this image changes lives in build_files/build.sh
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
