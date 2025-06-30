#!/bin/bash

generate_from_template() {
    local template_path="$1"
    local output_path="$2"
    local translations_path="$3"
    local current_locale="$4"

    if [ ! -f "$template_path" ]; then
        echo ":: AVISO: Template não encontrado em $template_path. Pulando geração."
        if [ ! -f "$output_path" ]; then touch "$output_path"; fi
        return
    fi
    
    echo ":: Gerando '$output_path' a partir de '$template_path'..."
    local config_content
    config_content=$(cat "$template_path")

    while IFS= read -r -d '' key && IFS= read -r -d '' value; do
        local placeholder="__$(echo "$key" | tr '[:lower:]' '[:upper:]')__"
        config_content="${config_content//$placeholder/$value}"
    done < <(jq -j ".\"$current_locale\" | to_entries | .[] | .key, \"\u0000\", .value, \"\u0000\"" "$translations_path")

    echo "$config_content" > "$output_path"
}


killall -q waybar
sleep 0.2

themestyle="/ml4w-minimal;/ml4w-minimal"
if [ -f ~/.config/ml4w/settings/waybar-theme.sh ]; then
    themestyle=$(cat ~/.config/ml4w/settings/waybar-theme.sh)
fi
IFS=';' read -ra arrThemes <<<"$themestyle"
THEME_CONFIG_DIR=~/.config/waybar/themes${arrThemes[0]}
THEME_STYLE_DIR=~/.config/waybar/themes${arrThemes[1]}
echo ":: Theme Config Dir: $THEME_CONFIG_DIR"
echo ":: Theme Style Dir: $THE_STYLE_DIR"


WAYBAR_DIR="$HOME/.config/waybar"
ML4W_SETTINGS_DIR="$HOME/.config/ml4w/settings"
TRANSLATIONS_FILE="$WAYBAR_DIR/translations.json"

CURRENT_LOCALE=$(echo $LANG | cut -d. -f1)
DEFAULT_LOCALE="en_US"
if ! jq -e ".\"$CURRENT_LOCALE\"" "$TRANSLATIONS_FILE" > /dev/null 2>&1; then
    CURRENT_LOCALE=$DEFAULT_LOCALE
fi
echo ":: Locale para tradução: $CURRENT_LOCALE"

generate_from_template \
    "$WAYBAR_DIR/modules.json.template" \
    "$WAYBAR_DIR/modules.json" \
    "$TRANSLATIONS_FILE" \
    "$CURRENT_LOCALE"

generate_from_template \
    "$ML4W_SETTINGS_DIR/waybar-quicklinks.json.template" \
    "$ML4W_SETTINGS_DIR/waybar-quicklinks.json" \
    "$TRANSLATIONS_FILE" \
    "$CURRENT_LOCALE"

config_template_name="config.template"
config_output_name="config"
if [ -f "$THEME_CONFIG_DIR/config-custom.template" ]; then
    config_template_name="config-custom.template"
    config_output_name="config-custom"
fi
generate_from_template \
    "$THEME_CONFIG_DIR/$config_template_name" \
    "$THEME_CONFIG_DIR/$config_output_name" \
    "$TRANSLATIONS_FILE" \
    "$CURRENT_LOCALE"


config_file_to_use="config"

if [ -f "$THEME_CONFIG_DIR/config-custom" ]; then
    config_file_to_use="config-custom"
fi
style_file_to_use="style.css"
if [ -f "$THEME_STYLE_DIR/style-custom.css" ]; then
    style_file_to_use="style-custom.css"
fi

if [ ! -f $HOME/.config/ml4w/settings/waybar-disabled ]; then
    waybar -c "$THEME_CONFIG_DIR/$config_file_to_use" -s "$THEME_STYLE_DIR/$style_file_to_use" &
else
    echo ":: Waybar disabled"
fi
