#!/usr/bin/bash
# Runs once per image build on GitHub Actions, on top of Bluefin DX.
# VS Code, Docker, Homebrew, Bazaar, ujust, uupd, codecs and the rest come from
# Bluefin DX unchanged. This script only adds COSMIC and makes it the desktop.
# If anything here fails, nothing gets published and your machine keeps the
# last good image.

set -ouex pipefail

### 1. Install COSMIC (Fedora's packages) -----------------------------------------
# Installing COSMIC may add packages and update Fedora ones, but nothing Bluefin
# already ships may disappear or switch source. Swapping negativo17's mesa or
# ffmpeg for Fedora's stripped builds, for example, would silently lose codecs
# and hardware video decode, so the build fails instead.
snapshot() { rpm -qa --queryformat='%{NAME}\t%{PACKAGER}\n' | LC_ALL=C sort -u; }
before="$(snapshot)"

dnf5 -y install @cosmic-desktop-environment

changed="$(LC_ALL=C comm -23 <(echo "${before}") <(snapshot))"
if [[ -n "${changed}" ]]; then
    echo "Installing COSMIC removed or replaced these Bluefin packages (name, packager):" >&2
    echo "${changed}" >&2
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

### 4. Files from system_files/ ---------------------------------------------------
# System76's COSMIC Flatpak remote (home of applets like Minimon) and the
# Flatpaks preinstalled on first boot. Copied after step 2, in case COSMIC Store
# shipped its own copy of the remote file.
cp -avf /ctx/system_files/. /
rm -f /etc/.gitkeep /usr/.gitkeep
