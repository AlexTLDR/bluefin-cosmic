# Purge leftover GNOME flatpaks. They survive rebases because they live in
# your home directory, not in the image - run this once after rebasing:
#   ujust purge-gnome-flatpaks

purge-gnome-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail
    FLATPAKS=(
        org.gnome.Snapshot          # Camera
        org.gnome.SimpleScan        # Document Scanner
        org.gnome.Loupe             # Image Viewer
        org.gnome.Showtime          # Video Player
        org.gnome.Decibels          # Audio Player
        # org.gnome.Calculator      # kept: no COSMIC calculator exists
        org.gnome.Calendar
        org.gnome.Characters
        org.gnome.Clocks
        org.gnome.Connections
        org.gnome.Contacts
        org.gnome.Maps
        org.gnome.Weather
        org.gnome.Logs
        org.gnome.Papers
        org.gnome.Extensions
        org.gnome.NautilusPreviewer
        org.gnome.FileRoller
        # org.gnome.Firmware        # fwupd GUI - no COSMIC equivalent, keep
        # org.gnome.DejaDup         # backups - keep if you use it
    )
    for app in "${FLATPAKS[@]}"; do
        flatpak uninstall --user -y "$app" 2>/dev/null || true
        flatpak uninstall --system -y "$app" 2>/dev/null || true
    done
    flatpak uninstall --unused -y || true
    echo "Done. GNOME flatpaks purged."
