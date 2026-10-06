#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# Install the LATEST release RPM of the COSMIC system monitor applet.
# GitHub's /releases/latest/download/ shortcut cannot be used here because the
# asset filename embeds the version - resolve it via the GitHub API instead.
URL=$(curl -fsSL "https://api.github.com/repos/D-Brox/cosmic-ext-applet-system-monitor/releases/latest" \
    | python3 -c "
import json, sys
assets = json.load(sys.stdin)['assets']
rpms = [a['browser_download_url'] for a in assets
        if a['name'].endswith('.rpm') and 'x86_64' in a['name']]
print(rpms[0])
")
echo "Installing cosmic-ext-applet-system-monitor from: $URL"
dnf5 -y install "$URL"
