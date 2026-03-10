# Ascii art color
color="#FFFFC5"
# How often to run the calculation for current moon phase
update_frequency_hours=6
# What art file to use for output
mode="ascii"
# Where to output the art file
output_dir="$XDG_RUNTIME_DIR"/PhaseFetch
# Where to get the art files from
system_data_dir="$(dirname "$(realpath "$0")")"
user_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/PhaseFetch"

# If not locally testing, use the usr dir
if [ -d "/usr/share/PhaseFetch" ]; then
    data_dir="/usr/share/PhaseFetch"
fi

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
        -h | --help)
            echo "PhaseFetch is an extendable tool that calculates which is the current moon phase and selects an art file based on current moon phase and artstyle selected"
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -c, --color <hex>               Hex color for moon display (default: #FFFFC5)"
            echo "  -u, --update-frequency <hours>  How often to refresh the moon phase, in hours (default: 6)"
            echo "  -o, --output-dir                The directory in which the current moon phase art file will be stored (default: $XDG_RUNTIME_DIR/PhaseFetch)"
            echo "  -m, --mode <mode>               Display mode. Valid values: 'ascii', 'png' (default: ascii)"
            echo "  -h, --help                      Show this help message"
            exit 0
        ;;
    esac
    shift
done

# File names containing appropriate art to be displayed
phase_file_names=("new_moon" "waxing_crescent" "first_quarter" "waxing_gibbous" "full_moon" "waning_gibbous" "last_quarter" "waning_crescent")

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

# Determine if the art is an image or ascii art and write/copy it's contents to an output file
write_phase() {
    mkdir -p "$output_dir"
    local file="$data_dir/$mode/${phase_file_names[$moon_phase]}"

    if file "$file" | grep -q "PNG"; then
        local out="$output_dir/current_phase.png"
        cp "$file" "$out"
        echo "Copied to $out"
    else
        local out="$output_dir/current_phase.ans"
        print_colored "$color" "$file" > "$out"
        echo "Wrote to $out"
    fi

    # Note that the file $out actually has an extension
    # Initially this function just overwrote the current_phase file, but once fastfetch detects the current_phase is a png, it won't render ascii art even after changing the mode to ascii
    # The workaround is to have separate png and ascii output files, but after updating them, link the current_phase to the correct one
    ln -sf "$out" "$output_dir/current_phase"
}

while true; do
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

    # see how many days have passed since last new moon
    # moduo that with the length of a moon cycle
    # approximate the phase by dividing by 3.691 (not all phases last the same amount of time, but if they did, it would be 3.691, that's why I said 'approximate')
    moon_phase=$(awk "BEGIN {
      diff = ($(date +%s) - $(date +%s -d "2000-01-06 18:14 UTC")) / 86400
      age = diff % 29.53059
      if (age < 0) age = age + 29.53059

      phase = age / 3.691
      if (phase > 7) phase = 7
      print int(phase)
    }")

    # Write art corresponding to the phase into the output file
    write_phase

    # Sleep for the specified amount of hourse and repeat
    sleep "$update_frequency_hours"h
done
