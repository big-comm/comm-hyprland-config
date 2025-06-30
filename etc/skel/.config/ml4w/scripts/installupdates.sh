#!/bin/bash
#    ____         __       ____               __     __
#   /  _/__  ___ / /____ _/ / / __ _____  ___/ /__ _/ /____ ___
#  _/ // _ \(_-</ __/ _ `/ / / / // / _ \/ _  / _ `/ __/ -_|_-<
# /___/_//_/___/\__/\_,_/_/_/  \_,_/ .__/\_,_/\_,_/\__/\__/___/
#                                 /_/
#

sleep 1
clear

TRANSLATIONS_FILE="$HOME/.config/waybar/translations.json"

CURRENT_LOCALE=$(echo $LANG | cut -d. -f1)
DEFAULT_LOCALE="en_US"
if ! jq -e ".\"$CURRENT_LOCALE\"" "$TRANSLATIONS_FILE" > /dev/null 2>&1; then
    CURRENT_LOCALE=$DEFAULT_LOCALE
fi


get_string() {
    jq -r ".\"$CURRENT_LOCALE\".$1 // .\"$DEFAULT_LOCALE\".$1" "$TRANSLATIONS_FILE"
}

TITLE_UPDATES=$(get_string "updates_title")
PROMPT_START_UPDATE=$(get_string "prompt_start_update")
MSG_UPDATE_STARTED=$(get_string "msg_update_started")
MSG_UPDATE_CANCELED=$(get_string "msg_update_canceled")
PROMPT_CREATE_SNAPSHOT=$(get_string "prompt_create_snapshot")
PLACEHOLDER_SNAPSHOT_COMMENT=$(get_string "placeholder_snapshot_comment")
MSG_SNAPSHOT_CREATED=$(get_string "msg_snapshot_created")
MSG_SNAPSHOT_SKIPPED=$(get_string "msg_snapshot_skipped")
ERR_PLATFORM_NOT_SUPPORTED=$(get_string "err_platform_not_supported")
MSG_PRESS_ENTER_TO_CLOSE=$(get_string "msg_press_enter_to_close")
MSG_UPDATE_COMPLETE=$(get_string "msg_update_complete")
# ----------------------------------------------------- 

install_platform="$(cat ~/.config/ml4w/settings/platform.sh)"
figlet -f smslant "$TITLE_UPDATES"
echo

# ------------------------------------------------------
# Confirm Start
# ------------------------------------------------------

if gum confirm "$PROMPT_START_UPDATE"; then
    echo
    echo "$MSG_UPDATE_STARTED"
elif [ $? -eq 130 ]; then
    exit 130
else
    echo
    echo "$MSG_UPDATE_CANCELED"
    exit
fi

_isInstalled() {
    package="$1"
    case $install_platform in
        arch)
            aur_helper="$(cat ~/.config/ml4w/settings/aur.sh)"
            check="$($aur_helper -Qs --color always "${package}" | grep "local" | grep "${package} ")"
            ;;
        fedora)
            check="$(dnf repoquery --quiet --installed ""${package}*"")"
            ;;
        *) ;;
    esac

    if [ -n "${check}" ]; then
        echo 0 #'0' means 'true' in Bash
        return #true
    fi
    echo 1 #'1' means 'false' in Bash
    return #false
}

# Check if platform is supported
case $install_platform in
    arch)
        aur_helper="$(cat ~/.config/ml4w/settings/aur.sh)"

        if [[ $(_isInstalled "timeshift") == "0" ]]; then
            echo
            if gum confirm "$PROMPT_CREATE_SNAPSHOT"; then
                echo
                c=$(gum input --placeholder "$PLACEHOLDER_SNAPSHOT_COMMENT")
                sudo timeshift --create --comments "$c"
                sudo timeshift --list
                sudo grub-mkconfig -o /boot/grub/grub.cfg
                printf "$MSG_SNAPSHOT_CREATED\n" "$c"
                echo
            elif [ $? -eq 130 ]; then
                echo "$MSG_SNAPSHOT_SKIPPED"
                exit 130
            else
                echo "$MSG_SNAPSHOT_SKIPPED"
            fi
            echo
        fi

        $aur_helper

        if [[ $(_isInstalled "flatpak") == "0" ]]; then
            flatpak upgrade
        fi
        ;;
    fedora)
        sudo dnf upgrade
        if [[ $(_isInstalled "flatpak") == "0" ]]; then
            flatpak upgrade
        fi
        ;;
    *)
        echo "$ERR_PLATFORM_NOT_SUPPORTED"
        echo "$MSG_PRESS_ENTER_TO_CLOSE"
        read
        ;;
esac

notify-send "$MSG_UPDATE_COMPLETE"
echo
echo ":: $MSG_UPDATE_COMPLETE"
echo
echo

echo "$MSG_PRESS_ENTER_TO_CLOSE"
read
