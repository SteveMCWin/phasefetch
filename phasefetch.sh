#!/bin/bash

set -e

###########################
####### GLOBAL VARS #######
###########################

# Ascii art color / PNG tint color
color=""
# How often to run the calculation for current moon phase
update_frequency_hours=8
# Run once to just update the current_phase with desired art
once=false
# Which art to display when running. Ignores calculation
phase_file=""
# What art file to use for output
mode="ascii"
# Where to output the art file
output_dir="$XDG_RUNTIME_DIR"/phasefetch
# File names containing appropriate art to be displayed
phase_file_names=("new_moon" "waxing_crescent" "first_quarter" "waxing_gibbous" "full_moon" "waning_gibbous" "last_quarter" "waning_crescent")
# The directory from which the art will be pulled from
data_dir=""

# Where to get the art files from
system_data_dir="$(dirname "$(realpath "$0")")"
user_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/phasefetch"

# If not locally testing, use the usr dir
if [ -d "/usr/share/phasefetch" ]; then
    system_data_dir="/usr/share/phasefetch"
fi

#############################
####### HANDLE PARAMS #######
#############################

# Check for parameters
while [ $# -gt 0 ]; do
    case $1 in
        -c | --color)
            if [ -n "$2" ] && [ "$2" != -* ]; then
                color=$2
                shift
            fi
        ;;
        -u | --update-frequency)
            if [ -n "$2" ] && [ "$2" != -* ]; then
                if ! [[ "$2" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                    echo "Error: --update-frequency must be a number" >&2
                    exit 1
                fi
                update_frequency_hours=$2
                shift
            fi
        ;;
        -m | --mode)
            if [ -n "$2" ] && [ "$2" != -* ]; then
                mode=$2
                shift
            fi
        ;;
        -o | --output-dir)
            if [ -n "$2" ] && [ "$2" != -* ]; then
                output_dir=$2
                shift
            fi
        ;;
        -f | --file)
            if [ -n "$2" ] && [ "$2" != -* ]; then
                phase_file=$2
                shift
            fi
        ;;
        --once)
            once=true
        ;;
        -h | --help)
            echo "PhaseFetch is an extendable tool that calculates which is the current moon phase and selects an art file based on current moon phase and artstyle selected"
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -c, --color <hex>               Hex color to tint the moon. For ASCII art, applies color via escape sequences. For PNG modes, tints the image with ImageMagick (requires 'magick' or 'convert'). No tint applied by default. Note: put the '#' hex color in quotes"
            echo "  -u, --update-frequency <hours>  How often to refresh the moon phase, in hours (default: 8)"
            echo "  -o, --output-dir                The directory in which the current moon phase art file will be stored (default: $XDG_RUNTIME_DIR/phasefetch)"
            echo "  -m, --mode <mode>               Display mode. Valid values: 'ascii', 'realistic', 'minecraft', 'minimal' (default: ascii)"
            echo "  -f, --file <file>               Which art file to display for current mode. Overwrites the phase calculation. Valid options are: ${phase_file_names[*]}"
            echo "      --once                      Run the script once to update the output art. Use this if you don't want to Ctrl+C after running the script manually"
            echo "  -h, --help                      Show this help message"
            exit 0
        ;;
        *)
            echo "Error: unrecognized option '$1'" >&2
            echo "Run '$(basename "$0") --help' for usage." >&2
            exit 1
        ;;
    esac
    shift
done

# Check if the phase_file the user selected is valid
if [ -n "$phase_file" ]; then
    valid=false
    for name in "${phase_file_names[@]}"; do
        if [ "$phase_file" = "$name" ]; then
            valid=true
            break
        fi
    done
    if ! $valid; then
        echo "Error: '$phase_file' is not a valid phase file name." >&2
        echo "Valid options: ${phase_file_names[*]}" >&2
        exit 1
    fi
fi

#################################
####### UTILITY FUNCITONS #######
#################################

# Util func to make the text colored for ascii art using escape sequences
print_colored() {
  local hex="${1#\#}"
  local r=$((16#${hex:0:2}))
  local g=$((16#${hex:2:2}))
  local b=$((16#${hex:4:2}))
  printf "\e[38;2;${r};${g};${b}m"
  cat "$2"
  printf "\e[0m\n"
}

# Checks if the passed mode exists and has all expected files
check_mode_validity() {
    # Check whether the mode is defined in the user dir or system dir, check user directory first
    if [ -d "$user_data_dir/$mode" ]; then
        data_dir="$user_data_dir"
    elif [ -d "$system_data_dir/$mode" ]; then
        data_dir="$system_data_dir"
    else
        echo "Error: mode '$mode' not found in $user_data_dir or $system_data_dir" >&2
        exit 1
    fi

    # Check if all files from phase_file_names exist in the mode folder
    missing_files=()
    for phase in "${phase_file_names[@]}"; do
        if [ ! -f "$data_dir/$mode/$phase" ]; then
            missing_files+=("$phase")
        fi
    done

    # If there are missing files, display which ones and exit
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo "Error: missing phase files for mode '$mode' in $data_dir/$mode:" >&2
        for f in "${missing_files[@]}"; do
            echo "  - $f" >&2
        done
        exit 1
    fi
}

# Determine if the art is an image or ascii art and write/copy it's contents to an output file
write_phase() {
    mkdir -p "$output_dir"

    # if file not set, use the calculated one
    # the 'name' var is used as a suffix to prevent terminal image cache from displaying old images
    if [ -n "$phase_file" ]; then
        local file="$data_dir/$mode/$phase_file"
        local name="$phase_file"
    else
        local file="$data_dir/$mode/${phase_file_names[$moon_phase]}"
        local name="${phase_file_names[$moon_phase]}"
    fi

    if file "$file" | grep -q "PNG"; then
        local color_suffix="${color//#/}"
        local out="$output_dir/${mode}_${name}${color_suffix:+_$color_suffix}.png"
        if command -v magick &>/dev/null && [ "$color" != "" ]; then
            magick "$file" -fill "$color" -tint 100 "$out"
        elif command -v convert &>/dev/null && [ "$color" != "" ]; then
            convert "$file" -fill "$color" -tint 100 "$out"
        else
            cp "$file" "$out"
        fi
    else
        local out="$output_dir/${mode}_${name}.ans"
        if [ -n "$color" ]; then
            print_colored "$color" "$file" > "$out"
        else
            cat "$file" > "$out"
        fi
    fi

    # Note that the file $out actually has an extension
    # Initially this function just overwrote the current_phase file, but once fastfetch detects the current_phase is a png, it won't render ascii art even after changing the mode to ascii
    # The workaround is to have separate png and ascii output files, but after updating them, link the current_phase to the correct one
    ln -sf "$out" "$output_dir/current_phase"
}


##########################
####### CORE LOGIC #######
##########################

while true; do
    check_mode_validity


    # see how many days have passed since last new moon
    # moduo that with the length of a moon cycle
    # divide the cycle into 8 equal sectors, offset by 0.5 so each phase is centered on its defining moment rather than starting at it
    moon_phase=$(awk "BEGIN {
      diff = ($(date +%s) - $(date +%s -d "2026-02-17 12:01 UTC")) / 86400
      age = diff % 29.53059
      if (age < 0) age = age + 29.53059

      sector = (age * 8 / 29.53059 + 0.5) % 8
      print int(sector)
    }")

    # Write art corresponding to the phase into the output file
    write_phase

    # If user specified the 'once' flag, we don't loop
    if $once; then
        exit 0
    fi

    # Sleep for the specified amount of hourse and repeat
    sleep "$update_frequency_hours"h
done
