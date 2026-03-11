# 🌙 PhaseFetch

PhaseFetch is a lightweight, extensible bash script that calculates the current moon phase and writes the corresponding art to a file. It's designed to integrate with system fetch tools like [FastFetch](https://github.com/fastfetch-cli/fastfetch), updating your terminal with a live moon phase display that refreshes automatically in the background.

![moon phases: new, crescent, quarter, gibbous, full](https://img.shields.io/badge/phases-8-silver) ![bash](https://img.shields.io/badge/shell-bash-89e051)

---

## Features

- Calculates the current lunar phase based on real astronomical math
- Supports multiple display modes: ASCII art and PNG images
- Fully extensible — add your own art modes without touching the source
- User modes take priority over system modes, with no conflicts
- Integrates with FastFetch for a live moon phase in your terminal fetch

---

## Quickstart

The steps to get this working with FastFetch:

- [Install dependencies](#dependencies)
- [Install phasefetch](#installation)
- [Autostart](#autostart)
- [Integrate into FastFetch config](#integrating-with-fastfetch)

---

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `bash` | Running the script |
| `awk` | Moon phase calculation |
| `file` | Detecting PNG vs ASCII art files |
| `coreutils` | `date`, `sleep`, `ln`, `cp`, `mkdir` |
| `fastfetch` | Displaying the output |

All of these are standard on any Linux system except FastFetch, which is optional if you wish to use this for something other than having a moon in your terminal.

---

## Installation

### Arch Linux (AUR)

```bash
yay -S phasefetch
# or
paru -S phasefetch
```

### Build from Source

```bash
git clone https://github.com/SteveMCWin/PhaseFetch.git
cd phasefetch
chmod +x install.sh
./install.sh
```

The install script copies the mode data to `/usr/share/phasefetch/` and the script to `/usr/local/bin/phasefetch`.

---

## Usage

```
phasefetch [OPTIONS]

Options:
  -c, --color <hex>               Hex color for moon display (default: #FFFFC5)
  -u, --update-frequency <hours>  How often to refresh the moon phase, in hours (default: 6)
  -o, --output-dir <path>         Directory to store the current moon phase art (default: $XDG_RUNTIME_DIR/phasefetch)
  -m, --mode <mode>               Display mode — any folder name in your data dir (default: ascii)
  -h, --help                      Show this help message
```

### Examples

```bash
# Run with defaults (ascii, updates every 6 hours)
phasefetch

# Use PNG mode with a cooler white color, refresh every 12 hours
phasefetch --mode png --color "#E8E8FF" --update-frequency 12

# Use a custom mode you created
phasefetch --mode neon_ascii
```
> **Note:** phasefetch runs in a loop, running it straight in the terminal will make it look like nothing is happening

---

## Integrating with FastFetch

PhaseFetch writes the current moon phase art to `$XDG_RUNTIME_DIR/phasefetch/current_phase`, which FastFetch can use as an image/art source.

Add the following to your FastFetch config (usually `~/.config/fastfetch/config.jsonc`):

```jsonc
{
    "logo": {
        "source": "$XDG_RUNTIME_DIR/phasefetch/current_phase",
        "type": "auto"
    }
}
```

> **Note:** PhaseFetch must be running in the background *before* FastFetch starts, so the output file exists when FastFetch reads it. See the [autostart](#autostart) section below.

---

## Autostart

PhaseFetch runs as a background loop, recalculating the phase and refreshing the output file at the interval you set. You need to start it automatically with your session.

### Hyprland

Add to `~/.config/hypr/hyprland.conf`:

```ini
exec-once = phasefetch --mode ascii --update-frequency 8
```

### i3 / Sway

Add to `~/.config/i3/config` or `~/.config/sway/config`:

```ini
exec --no-startup-id phasefetch --mode ascii --update-frequency 8
```

### KDE Plasma (Autostart)

Go to **System Settings → Autostart → Add Script** and point it to a small wrapper:

```bash
#!/bin/bash
phasefetch --mode ascii --update-frequency 8
```

### systemd user service (DE-agnostic)

Create `~/.config/systemd/user/phasefetch.service`:

```ini
[Unit]
Description=PhaseFetch moon phase updater

[Service]
ExecStart=/usr/local/bin/phasefetch --mode ascii --update-frequency 8
Restart=on-failure

[Install]
WantedBy=default.target
```

Then enable it:

```bash
systemctl --user enable --now phasefetch.service
```

This works regardless of your desktop environment and survives session restarts.

---

## Adding Custom Modes

PhaseFetch looks for modes in two places, with your user directory taking priority:

| Directory | Owner | Purpose |
|-----------|-------|---------|
| `/usr/share/phasefetch/` | Package | Built-in modes (`ascii`, `png`, `png_256`, …) |
| `~/.local/share/phasefetch/` | You | Your custom or override modes |

To create a new mode, make a folder named after your mode and add one file per lunar phase, named exactly:

```
~/.local/share/phasefetch/
└── your_mode_name/
    ├── new_moon
    ├── waxing_crescent
    ├── first_quarter
    ├── waxing_gibbous
    ├── full_moon
    ├── waning_gibbous
    ├── last_quarter
    └── waning_crescent
```

Each file can be either:
- A **plain text / ANSI art** file — PhaseFetch will apply your `--color` tint and write it as `.ans`
- A **PNG image** — PhaseFetch will detect it automatically and copy it as `.png`

Once the folder exists, use it immediately with `--mode your_mode_name`. If PhaseFetch is already running, it will pick up the new mode on its next update cycle without needing a restart.

> If you want to **override** a built-in mode (e.g. `ascii`), do so by creating a folder with the same name in your user directory. Your version will always win.
> **Note:** You shouldn't simply change the files in the `/usr/share/phasefetch/` directory, your changes may be overwritten by future updates.

---

## License

MIT
