# bluefin-cosmic

Bluefin DX with COSMIC as the desktop, built with [ublue-os/image-template](https://github.com/ublue-os/image-template).

## What's in it

- **Everything from Bluefin DX, unchanged:** VS Code, Docker, Homebrew, Bazaar, `ujust`, uupd auto-updates, codecs, distrobox and devcontainers.
- **COSMIC** from Fedora's own packages, with the COSMIC greeter as the login screen.
- **GNOME stays installed underneath**, because Bluefin's tooling expects it, but the login screen doesn't offer it.
- **Bazaar is the only app store.** COSMIC Store is removed.
- **Preinstalled on first boot:** the Minimon panel applet (CPU, temperature, RAM, network, disk) and Firefox as a Flatpak, the same way Bluefin ships Firefox.

All the changes live in [`build_files/build.sh`](build_files/build.sh) and [`system_files/`](system_files).

## One-time setup

1. Replace `alextldr` in `image-template.env` and `disk_config/iso.toml`. Use lowercase, because GHCR paths must be lowercase.
2. Create a signing key and add it to the repo as the `SIGNING_SECRET` secret. Commit `cosign.pub`. `cosign.key` is git-ignored and must stay out of the repo.
3. Push to `main` and wait for the **Build container image** workflow to finish green. The first run takes a while.

After that, the image rebuilds daily and on every push. If a build fails, nothing is published, and installed machines keep the last good image.

## Installing

**Fresh install from a USB stick**

1. Go to Actions → **Build disk images** → Run workflow (amd64).
2. Download the ISO artifact.
3. Flash it, boot it, and install. The installer asks for the disk, your user and the timezone.

**Switching an existing Fedora Atomic install**

```
sudo rpm-ostree reset
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/alextldr/bluefin-cosmic:latest
systemctl reboot
```

Run both commands before rebooting. `reset` drops layered packages and overrides. If one of them is your login shell (zsh, for example), booting without it locks you out.

## After the first boot

- **Minimon on the panel:** Settings → Desktop → Panel → Applets.
- **Bluefin's default apps:** `ujust install-system-flatpaks`.
- **More dev tools (Zed, JetBrains Toolbox, Lima, …):** `ujust devmode`.
- **More COSMIC applets:** `flatpak remote-ls cosmic` lists them, and `flatpak install cosmic <id>` installs one.
- **Coming from Fedora's RPM Firefox:** the Flatpak doesn't pick up your old `~/.mozilla` profile. Use Firefox Sync, or move the profile over.
- **Updates** run automatically through uupd. `ujust update` runs them now.
- **Rolling back:** pick the previous entry in the boot menu, or run `sudo bootc rollback`.

## Notes

- **NVIDIA GPU:** change the `FROM` line in the `Containerfile` to `ghcr.io/ublue-os/bluefin-dx-nvidia-open:stable`.
- **Bluefin is moving away from the `-dx` images** and towards `ujust devmode`. If `bluefin-dx` ever stops updating, switch the `FROM` line to `ghcr.io/ublue-os/bluefin:stable`. Everything else in this repo works the same.
- **Removing an entry from `system_files/usr/share/flatpak/preinstall.d/`** uninstalls that app on the next boot. That's how Flatpak preinstall is designed.
