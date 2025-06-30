#!/bin/bash

WLOGOUT_DIR="$HOME/.config/wlogout"
TEMPLATE_FILE="$WLOGOUT_DIR/layout.template"
OUTPUT_FILE="$WLOGOUT_DIR/layout"
TRANSLATIONS_FILE="$HOME/.config/waybar/translations.json"

if [ -f "$TEMPLATE_FILE" ]; then
    # Detecção de Idioma
    CURRENT_LOCALE=$(echo $LANG | cut -d. -f1)
    DEFAULT_LOCALE="en_US"
    if ! jq -e ".\"$CURRENT_LOCALE\"" "$TRANSLATIONS_FILE" > /dev/null 2>&1; then
        CURRENT_LOCALE=$DEFAULT_LOCALE
    fi

    CONFIG_CONTENT=$(cat "$TEMPLATE_FILE")

    while IFS= read -r -d '' key && IFS= read -r -d '' value; do
        if [[ $key == wlogout_* ]]; then
            placeholder="__$(echo "$key" | tr '[:lower:]' '[:upper:]')__"
            CONFIG_CONTENT="${CONFIG_CONTENT//$placeholder/$value}"
        fi
    done < <(jq -j ".\"$CURRENT_LOCALE\" | to_entries | .[] | .key, \"\u0000\", .value, \"\u0000\"" "$TRANSLATIONS_FILE")

    echo "$CONFIG_CONTENT" > "$OUTPUT_FILE"
else
    echo "AVISO: Template $TEMPLATE_FILE não encontrado."
fi

res_w=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
res_h=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .height')
h_scale=$(hyprctl -j monitors | jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')
w_margin=$((res_h * 27 / h_scale))
# -----------------------------------------------------


wlogout -b 5 -T $w_margin -B $w_margin -p layer-shell
