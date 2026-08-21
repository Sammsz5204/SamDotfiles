# SamDotfiles

Personal dotfiles for my Arch Linux + Hyprland setup.

This repository contains the configuration I actually use on my desktop, with a focus on a clean Wayland workflow, dynamic theming, custom UI components, and a frankly unreasonable amount of time spent making tiny things look nicer.

> **Current UI stack:** Quickshell
>
> Waybar and Eww were part of earlier versions of the setup. They have been retired in favor of Quickshell.

## ✨ Highlights

- **Hyprland** configured with its Lua configuration system
- **Quickshell** for the status bar, widgets, system panel, taskbar, tray, volume controls and other desktop UI
- **Dynamic theming** generated from wallpapers
- **Hyprlock** and **Hyprpaper** for the lock screen and wallpaper setup
- **Rofi** for application launching
- **Kitty** as the terminal
- **Neovim** configured with LazyVim
- **btop** for system monitoring
- Custom scripts for wallpapers, colors, network statistics, Cava and system utilities

## 🖥️ Stack

| Component | Choice |
| --- | --- |
| OS | Arch Linux |
| Compositor | Hyprland |
| Shell / UI | Quickshell |
| Terminal | Kitty |
| Launcher | Rofi (Wayland) |
| Editor | Neovim / LazyVim |
| System monitor | btop |
| Notifications | SwayNC |
| Wallpaper | Hyprpaper |
| Lock screen | Hyprlock |
| Audio visualizer | Cava |
| GTK settings | nwg-look |
| Music | MPD + rmpc |

## 📁 Structure

```text
SamDotfiles/
├── btop/          # btop configuration
├── hypr/          # Hyprland, Hyprlock, Hyprpaper, fonts and colors
├── kitty/         # Kitty configuration and colors
├── nvim/          # Neovim / LazyVim configuration
├── nwg-look/      # GTK appearance settings
├── quickshell/    # Main desktop shell and UI components
├── rofi/          # Rofi configuration
└── scripts/       # Install, wallpaper, theming and utility scripts
```

### Quickshell

The current desktop UI lives in `quickshell/`.

It is split into reusable QML components rather than one enormous file that future me would eventually have to fear. The shell includes things such as:

- top bar
- clock
- taskbar
- system statistics
- system panel / popup
- tray
- volume controls
- idle inhibitor
- reusable buttons and animated components

The entry point creates a bar for every connected screen automatically, so monitors do not need to be manually listed in the shell configuration.

## 🎨 Dynamic theming

The setup uses the current wallpaper as the source for its color palette.

The scripts in `scripts/` handle color extraction and theme generation, with the resulting colors being consumed by Hyprland and the UI components.

The general flow is:

```text
Wallpaper
   ↓
Color extraction
   ↓
Generated palette
   ↓
Hyprland + Quickshell + other configs
```

Because apparently choosing colors manually became too primitive.

## 🚀 Installation

> **Warning:** these are my personal dotfiles. They are not a universal Arch Linux setup. Read the installer before running it, especially if you already have files in `~/.config` that you care about.

Clone the repository:

```bash
git clone https://github.com/Sammsz5204/SamDotfiles.git
cd SamDotfiles
```

Run the installer:

```bash
./scripts/install.sh
```

The installer can:

- install the required Arch packages
- back up existing configuration directories
- link the dotfiles into `~/.config`
- install the included fonts
- update the font cache
- initialize the wallpaper/theme setup

### Manual setup

If you prefer not to let a shell script rearrange your home directory, each directory can also be installed manually by symlinking it into `~/.config`.

For example:

```bash
ln -s "$PWD/hypr" ~/.config/hypr
ln -s "$PWD/quickshell" ~/.config/quickshell
```

## ⚠️ Notes

- This repository targets **Arch Linux**.
- The configuration assumes **Hyprland on Wayland**.
- Some paths and commands are specific to my machine and may need adjustment.
- The configuration is a work in progress and will change as the setup evolves.
- Old Waybar/Eww files may still exist while the repository is being cleaned up, but **Quickshell is the active UI implementation**.

## 📸 Screenshots

Screenshots will be added here as the rice stops changing every five minutes.

## 🛠️ Philosophy

I don't really aim for a "minimal" setup. I aim for a setup that feels coherent, is reasonably maintainable, and does what I want without making me fight it every time I change something.

This repo is primarily a backup and a record of the setup, but parts of it may be useful as references for other Hyprland / Quickshell users.

## 📜 License

See the individual project directories for their respective licenses. Configurations and scripts in this repository are provided as-is.