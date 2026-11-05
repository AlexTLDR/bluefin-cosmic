#!/usr/bin/bash
# Runs once per image build on GitHub Actions, on top of Bluefin DX.
# VS Code, Docker, Homebrew, Bazaar, ujust, uupd, codecs and the rest come from
# Bluefin DX unchanged. This script only adds COSMIC and makes it the desktop.
# If anything here fails, nothing gets published and your machine keeps the
# last good image.

set -ouex pipefail

### 1. Install COSMIC (Fedora's packages) -----------------------------------------
# Installing COSMIC may add packages and update Fedora ones, but nothing Bluefin
# already ships may silently disappear or switch source. Two replacements are
# fine: a same-source merge (Fedora renames/merges a package), and a move to
# negativo17, Bluefin's own multimedia source (e.g. Fedora's
# gstreamer1-plugins-bad-free -> negativo17's gstreamer1-plugins-bad, which also
# swaps FAAD for the better FDK-AAC). Anything else -- a real removal, or a swap
# like negativo17's mesa/ffmpeg for Fedora's stripped builds -- fails the build
# instead of quietly shipping without codecs or hardware video decode.
snapshot() { rpm -qa --queryformat='%{NAME}\t%{PACKAGER}\n' | LC_ALL=C sort -u; }
before="$(snapshot)"

dnf5 -y install @cosmic-desktop-environment

changed="$(LC_ALL=C comm -23 <(echo "${before}") <(snapshot))"
if [[ -n "${changed}" ]]; then
    rc=0
    while IFS=$'\t' read -r name packager; do
        # Which installed package, if any, obsoletes the vanished one?
        successors="$(dnf5 -q repoquery --installed --whatobsoletes "${name}" \
            --qf '%{name}\t%{packager}' 2>/dev/null || true)"
        if grep -q 'negativo17' <<< "${successors}" || grep -qF "${packager}" <<< "${successors}"; then
            echo "Allowed replacement: ${name} -> ${successors//$'\n'/, }"
        else
            echo "Installing COSMIC removed or replaced ${name} (${packager})" >&2
            rc=1
        fi
    done <<< "${changed}"
    (( rc == 0 )) || exit 1
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

### 4. Nerd Fonts for editors and terminals --------------------------------------
# Fedora doesn't package Nerd Fonts, so install the official release archives
# system-wide. Every Nerd Font ships the same icon glyphs, so these monospace
# families cover all icon rendering; append to NERD_FONTS to add another one.
# In font pickers, CascadiaCode appears as CaskaydiaCove and Meslo as MesloLG*.
# renovate: datasource=github-releases depName=ryanoasis/nerd-fonts
NERD_FONTS_VERSION="v3.5.1"
NERD_FONTS=(FiraCode JetBrainsMono CascadiaCode Meslo)
for font in "${NERD_FONTS[@]}"; do
    curl --retry 3 -fsSLo "/tmp/${font}.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/${font}.zip"
    install -d "/usr/share/fonts/nerd-fonts/${font}"
    unzip -q "/tmp/${font}.zip" -d "/usr/share/fonts/nerd-fonts/${font}"
done

# Fail the build if a family didn't register with fontconfig. grep reads a file,
# not a pipe: with pipefail, grep -q exiting early would SIGPIPE fc-list.
fc-cache -f
fc-list --format='%{file}\n' > /tmp/installed-fonts.txt
for font in "${NERD_FONTS[@]}"; do
    if ! grep -q "^/usr/share/fonts/nerd-fonts/${font}/" /tmp/installed-fonts.txt; then
        echo "${font} installed but did not register with fontconfig" >&2
        exit 1
    fi
done

### 5. Files from system_files/ ---------------------------------------------------
# System76's COSMIC Flatpak remote (home of applets like Minimon) and the
# Flatpaks preinstalled on first boot. Copied after step 2, in case COSMIC Store
# shipped its own copy of the remote file.
cp -avf /ctx/system_files/. /
rm -f /etc/.gitkeep /usr/.gitkeep

### 6. Proton VPN (GUI + CLI) from Proton's own RPM repo --------------------------
# Native packages, not the Flatpak: the app drives WireGuard through
# NetworkManager and a D-Bus/polkit daemon. system_files/ carries Proton's repo
# file verbatim (what their protonvpn-stable-release RPM installs), so daily
# rebuilds pick up app updates and $releasever follows Fedora upgrades.
# libappindicator-gtk3 is for the tray icon (COSMIC's App Tray applet).
# proton-vpn-daemon's %posttrans runs `systemctl daemon-reload` and `start`,
# which can't work during an image build and fail the dnf transaction. Its only
# scriptlets are those systemctl calls, so skip them and enable the unit here;
# on a booted system the daemon is also D-Bus activated on demand.
dnf5 -y install --setopt=tsflags=noscripts proton-vpn-daemon
dnf5 -y install proton-vpn-gnome-desktop libappindicator-gtk3
systemctl enable me.proton.vpn.split_tunneling.service

### 7. Appearance defaults --------------------------------------------------------
# All shipped via system_files/ (copied in step 5); per-user settings always win:
# - /usr/share/icons/Dracula-cursors + default/index.theme: cursor theme
# - /etc/environment.d/90-bluefin-cosmic.conf: XCURSOR_* for compositor/Qt/XWayland
# - /etc/dconf/db/local.d/99-bluefin-cosmic: GTK theme, icons, cursors, fonts
# - /usr/share/cosmic/: COSMIC theme (Dracula accent), terminal and wallpaper
# adw-gtk3-theme and open-sans-fonts already ship in Bluefin DX.
# dconf update compiles the new local db so the GTK defaults take effect.
dconf update
