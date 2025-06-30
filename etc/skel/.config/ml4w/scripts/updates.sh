#!/bin/bash
#  _   _           _       _             
# | | | |_ __   __| | __ _| |_ ___  ___  
# | | | | '_ \ / _` |/ _` | __/ _ \/ __| 
# | |_| | |_) | (_| | (_| | ||  __/\__ \ 
#  \___/| .__/ \__,_|\__,_|\__\___||___/ 
#       |_|                              
#  

script_name=$(basename "$0")
instance_count=$(ps aux | grep -F "$script_name" | grep -v grep | grep -v $$ | wc -l)
if [ $instance_count -gt 1 ]; then
    sleep $instance_count
fi

TRANSLATIONS_FILE="$HOME/.config/waybar/translations.json"

CURRENT_LOCALE=$(echo $LANG | cut -d. -f1)
DEFAULT_LOCALE="en_US"
if ! jq -e ".\"$CURRENT_LOCALE\"" "$TRANSLATIONS_FILE" > /dev/null 2>&1; then
    CURRENT_LOCALE=$DEFAULT_LOCALE
fi

TOOLTIP_UPDATES_AVAILABLE=$(jq -r ".\"$CURRENT_LOCALE\".update_system_tooltip // \"Click to update your system\"" "$TRANSLATIONS_FILE")
TOOLTIP_NO_UPDATES=$(jq -r ".\"$CURRENT_LOCALE\".no_updates_tooltip // \"No updates available\"" "$TRANSLATIONS_FILE")
# ----------------------------------------------------- 

# Define threshholds for color indicators
threshhold_green=0
threshhold_yellow=25
threshhold_red=100
install_platform="$(cat ~/.config/ml4w/settings/platform.sh)"

# Check if platform is supported
case $install_platform in
    arch)
        aur_helper="$(cat ~/.config/ml4w/settings/aur.sh)"
        check_lock_files() {
            local pacman_lock="/var/lib/pacman/db.lck"
            local checkup_lock="${TMPDIR:-/tmp}/checkup-db-${UID}/db.lck"
            while [ -f "$pacman_lock" ] || [ -f "$checkup_lock" ]; do
                sleep 1
            done
        }
        check_lock_files
        updates=$(checkupdates-with-aur | wc -l)
    ;;
    fedora)
        updates=$(dnf check-update -q | grep -c ^[a-z0-9])
    ;;
    *)
        updates=0
    ;;
esac

# ----------------------------------------------------- 
# Output in JSON format for Waybar Module custom-updates
# ----------------------------------------------------- 
css_class="green"
if [ "$updates" -gt $threshhold_yellow ]; then
    css_class="yellow"
fi
if [ "$updates" -gt $threshhold_red ]; then
    css_class="red"
fi

if [ "$updates" -gt $threshhold_green ]; then
    printf '{"text": "%s", "alt": "%s", "tooltip": "%s", "class": "%s"}' "$updates" "$updates" "$TOOLTIP_UPDATES_AVAILABLE" "$css_class"
else
    printf '{"text": "0", "alt": "0", "tooltip": "%s", "class": "green"}' "$TOOLTIP_NO_UPDATES"
fi
