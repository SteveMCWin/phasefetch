# 🌙 PhaseFetch

PhaseFetch is a lightweight, extensible bash script that calculates the current moon phase and writes the corresponding art to a file. It's designed to integrate seamlessly with system fetch tools like [FastFetch](https://github.com/fastfetch-cli/fastfetch), updating your terminal with a live moon phase display that refreshes automatically in the background.

![moon phases: new, crescent, quarter, gibbous, full](https://img.shields.io/badge/phases-8-silver) ![bash](https://img.shields.io/badge/shell-bash-89e051)

---

## Screenshots

<div align="center">
  <img src="screenshots/red_ascii_screenshot.png?raw=true" /><br/>
  <em>Ascii Moon - Red</em>
</div>

<div align="center">
  <img src="screenshots/minecraft_moon_screenshot.png?raw=true" /><br/>
  <em>Minecraft Moon - Credits to D_Dimensional</em>
</div>

---

## Features

- Calculates the current lunar phase based on real astronomical math
- Supports multiple display modes: ASCII art and PNG images
- Fully extensible — add your own art modes without touching the source
- User modes take priority over system modes, with no conflicts
- Integrates with FastFetch for a live moon phase in your terminal fetch

---

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `bash` | Running the script |
| `awk` | Moon phase calculation |
| `file` | Detecting PNG vs ASCII art files |
| `coreutils` | `date`, `sleep`, `ln`, `cp`, `mkdir` |
| `fastfetch` | *(optional)* Displaying the output |

All of these are standard on any Linux system except FastFetch, which is optional.

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
git clone https://github.com/yourusername/phasefetch.git
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
  -c, --color <hex>               Hex color to tint the moon. For ASCII art, applies color via escape sequences. For PNG modes, tints the image with ImageMagick (requires `magick` or `convert`). No tint applied by default. Note: put the '#' hex color in quotes
  -u, --update-frequency <hours>  How often to refresh the moon phase, in hours (default: 8)
  -o, --output-dir <path>         Directory to store the current moon phase art (default: $XDG_RUNTIME_DIR/phasefetch)
  -m, --mode <mode>               Display mode — built-in: `ascii`, `realistic`, `minecraft`, `minimal`, or any custom folder name (default: ascii)
  -f, --file <phase>              Override the phase calculation and display a specific phase. Valid values: new_moon, waxing_crescent, first_quarter, waxing_gibbous, full_moon, waning_gibbous, last_quarter, waning_crescent
      --once                      Write the output file once and exit instead of looping
  -h, --help                      Show this help message
```

### Examples

```bash
# Run with defaults (ascii, updates every 8 hours)
phasefetch

# Use realistic PNG mode with a blue tint, refresh every 12 hours
phasefetch --mode realistic --color "#E8E8FF" --update-frequency 12

# Use a custom mode you created
phasefetch --mode neon_ascii

# Force a specific phase to display regardless of the actual moon
phasefetch --file full_moon

# Write the output once and exit (useful for testing or manual runs)
phasefetch --once
```

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

> **Tip:** If FastFetch keeps showing a stale or incorrectly tinted image after changing modes or colors, clear FastFetch's image cache:
> ```bash
> rm -rf ~/.cache/fastfetch/
> ```

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
| `/usr/share/phasefetch/` | Package | Built-in modes (`ascii`, `realistic`, `minecraft`, `minimal`) |
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
- A **plain text / ANSI art** file — PhaseFetch will apply your `--color` tint (if set) and write it as `.ans`
- A **PNG image** — PhaseFetch will detect it automatically. If `--color` is set and ImageMagick is available, the image will be tinted to that color; otherwise it is copied as-is.

Once the folder exists, use it immediately with `--mode your_mode_name`. If PhaseFetch is already running, it will pick up the new mode on its next update cycle without needing a restart.

> You can also **override** a built-in mode (e.g. `ascii`) by creating a folder with the same name in your user directory. Your version will always win.

---

## License

MIT
