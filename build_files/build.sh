#!/usr/bin/bash
# Runs once per image build on GitHub Actions, on top of Bluefin DX.
# VS Code, Docker, Homebrew, Bazaar, ujust, uupd, codecs and the rest come from
# Bluefin DX unchanged. This script only adds COSMIC and makes it the desktop.
# If anything here fails, nothing gets published and your machine keeps the
# last good image.

set -ouex pipefail

### 1. Install COSMIC (Fedora's packages) -----------------------------------------
# Bluefin's graphics and codec stack comes from negativo17. If installing COSMIC
# ever swaps any of it for Fedora's stripped builds, fail the build instead of
# quietly shipping an image without codecs or hardware video decode.
PROTECTED=(mesa-dri-drivers mesa-vulkan-drivers libva libheif ffmpeg-libs)
before="$(rpm -q "${PROTECTED[@]}" || true)"

dnf5 -y install @cosmic-desktop-environment

after="$(rpm -q "${PROTECTED[@]}" || true)"
if [[ "${before}" != "${after}" ]]; then
    echo "Installing COSMIC changed Bluefin's graphics/codec packages:" >&2
    diff <(echo "${before}") <(echo "${after}") >&2 || true
    exit 1
fi

### 2. Bazaar instead of COSMIC Store; keep Bluefin's removals removed ------------
# The COSMIC group can pull back packages Bluefin deliberately leaves out
# (on Bluefin, Firefox is a Flatpak).
UNWANTED=(
    cosmic-store
    fedora-bookmarks
    fedora-chromium-config
    firefox
    firefox-langpacks
)
readarray -t installed < <(rpm -qa --queryformat='%{NAME}\n' "${UNWANTED[@]}")
if [[ "${#installed[@]}" -gt 0 ]]; then
    dnf5 -y remove "${installed[@]}"
fi

### 3. COSMIC greeter instead of GDM, COSMIC as the only session -----------------
# GNOME stays installed underneath because Bluefin's own tooling expects it;
# it just isn't offered at the login screen.
systemctl disable gdm.service
systemctl enable cosmic-greeter.service
rm -f /usr/share/wayland-sessions/gnome*.desktop /usr/share/xsessions/gnome*.desktop

### 4. System76's COSMIC Flatpak remote, home of panel applets like Minimon -------
# Done after step 2, in case COSMIC Store shipped its own copy of this file.
mkdir -p /usr/share/flatpak/remotes.d
curl --retry 3 -fsSLo /usr/share/flatpak/remotes.d/cosmic.flatpakrepo \
    https://apt.pop-os.org/cosmic/cosmic.flatpakrepo

### 5. Files from system_files/ (Flatpaks preinstalled on first boot, ...) --------
cp -avf /ctx/system_files/. /
rm -f /etc/.gitkeep /usr/.gitkeep
