# bluefin-cosmic &nbsp; [![bluebuild build badge](https://github.com/AlexTLDR/bluefin-cosmic/actions/workflows/build.yml/badge.svg)](https://github.com/AlexTLDR/bluefin-cosmic/actions/workflows/build.yml)

Bluefin DX with the [COSMIC](https://github.com/pop-os/cosmic-epoch) desktop environment instead of GNOME. All the Bluefin/DX tooling (dev tools, containers, brew, ujust, …), none of the GNOME desktop.

Based on [`ghcr.io/ublue-os/bluefin-dx:stable`](https://github.com/ublue-os/bluefin).

## What this image does

- Installs the full COSMIC desktop from the **official Fedora repos** — session, `cosmic-greeter`, settings, files, edit, term, store, player, screenshots, wallpapers, …
- Replaces GDM with `cosmic-greeter` (via `greetd`)
- Removes the GNOME session/shell and every GNOME app that COSMIC does not use (Files, Disks, System Monitor, Online Accounts, Evolution Data Server, the works)
- Keeps only the GNOME components COSMIC silently relies on:
  - `gnome-keyring` — provides the secret service used for Wi-Fi passwords and logins
  - `xdg-desktop-portal-gtk` — file chooser / print / inhibit portals that `xdg-desktop-portal-cosmic` does not implement yet
  - `xdg-desktop-portal-gnome` — invisible portal fallback some flatpaks rely on (add it to the removal list in `recipes/recipe.yml` if you want maximum purity)
- Automatically purges the GNOME flatpaks that Bluefin pre-installs (Snapshot, Calendar, Loupe, …) — a one-time systemd service removes them on first boot and never runs again. `org.gnome.Calculator` is kept (no COSMIC calculator exists) and `ujust purge-gnome-flatpaks` is shipped for manual/user-scope cleanup.

## Installation

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/alextldr/bluefin-cosmic:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/alextldr/bluefin-cosmic:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

> [!NOTE]
> Your existing user flatpaks survive the rebase. If you were running Bluefin before, you may want to uninstall GNOME flatpaks you no longer need (`flatpak uninstall --unused` and/or `flatpak remove org.gnome.Calculator org.gnome.Calendar …`).
>
> Layered packages (`rpm-ostree install …`) also survive rebases. Never layer GNOME packages (e.g. `gnome-tweaks`) — they pull the whole GNOME desktop back as dependencies. Check with `rpm-ostree status` and remove with `sudo rpm-ostree uninstall <pkg>`.
>
> **Kernel note (thunderbolt):** the image ships `thunderbolt.host_reset=0` to work around a kernel 7.2.x regression that hangs poweroff when a USB4 dock was connected (Lenovo USB4 Dock + Clevo/Lunar Lake firmware). On machines installed via `bootc` this applies automatically; after an `rpm-ostree rebase` to this image, run once: `sudo rpm-ostree kargs --append-if-missing=thunderbolt.host_reset=0`. Remove once Fedora ships the fixed kernel.

## Building locally / making your own

This repo follows the [BlueBuild](https://blue-build.org/) template — see the [docs](https://blue-build.org/how-to/setup/) for how to set up your own repository, container signing, and GitHub Actions secrets (`SIGNING_SECRET`).

## ISO

If built on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/how-to/generate-iso/#_top). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/alextldr/bluefin-cosmic
```
