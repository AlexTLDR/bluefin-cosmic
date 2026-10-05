#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# Point greetd at the COSMIC greeter instead of its default text-mode agreety
# config. /etc/greetd/config.toml is owned by the greetd package; replacing it
# with a symlink means future greetd updates keep the symlink and drop their
# default config as config.toml.rpmnew.
ln -sf /etc/greetd/cosmic-greeter.toml /etc/greetd/config.toml

# Remove the display-manager symlink left dangling by the removed gdm package.
rm -f /etc/systemd/system/display-manager.service

# greetd replaces gdm as the display manager. systemctl enable manipulates
# symlinks only, so it works at image build time; fall back to a manual
# symlink in /etc if the unit ever loses its [Install] section.
if ! systemctl enable greetd.service; then
    mkdir -p /etc/systemd/system/graphical.target.wants
    ln -sf /usr/lib/systemd/system/greetd.service \
        /etc/systemd/system/graphical.target.wants/greetd.service
fi
