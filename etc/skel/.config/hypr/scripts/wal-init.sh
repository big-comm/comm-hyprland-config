#!/bin/bash

FIRST_RUN_FLAG="$HOME/.config/hypr/first_run_complete"

if [ -f "$FIRST_RUN_FLAG" ]; then
    exit 0
fi

wal -i /usr/share/backgrounds/community/animal-hpr-001.jpg --saturate 0.6 &>/dev/null

mkdir -p "$(dirname "$FIRST_RUN_FLAG")"

touch "$FIRST_RUN_FLAG"
