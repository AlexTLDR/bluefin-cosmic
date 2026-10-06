#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# Proton VPN from the official Fedora repo.
# The release package adds the repo (protonvpn-fedora-stable) and its GPG key.
dnf5 -y install "https://repo.protonvpn.com/fedora-$(rpm -E %fedora)-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.4-1.noarch.rpm"

# The daemon's %posttrans scriptlet calls systemctl, which fails in image
# builds (systemd is not PID 1) and fails the whole rpm transaction.
# Skip scriptlets, then do the one unit enablement manually.
dnf5 -y --setopt=tsflags=noscripts install proton-vpn-gnome-desktop
systemctl enable me.proton.vpn.split_tunneling.service
