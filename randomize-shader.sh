#!/bin/bash
# Randomly pick a watercolor shader and color, then generate active-shader.glsl.
# Add to your .zshrc: source ~/code/ghostty-watercolors/randomize-shader.sh

SHADER_DIR="$HOME/code/ghostty-watercolors"
OUTPUT="$SHADER_DIR/active-shader.glsl"
TMP="$SHADER_DIR/.active-shader.tmp"

# List shader files explicitly to avoid bash/zsh array differences
shaders=(
    "flat-wash-bg.glsl"
    "graded-wash-bg.glsl"
    "variegated-wash-bg.glsl"
    "wet-on-wet-bg.glsl"
    "glazing-bg.glsl"
    "granulating-bg.glsl"
    "salt-bg.glsl"
    "cauliflower-bg.glsl"
    "splatter-bg.glsl"
)

count=${#shaders[@]}
index=$((RANDOM % count))
picked="$SHADER_DIR/${shaders[$index]}"

# Fallback if somehow the file doesn't exist
if [ ! -f "$picked" ]; then
    picked="$SHADER_DIR/flat-wash-bg.glsl"
fi

# Random hue between 0.0 and 1.0
hue=$(awk "BEGIN {srand(); printf \"%.3f\", rand()}")

# Generate to temp file, then atomic move
sed "s/WASH_HUE/$hue/g" "$picked" > "$TMP" && mv "$TMP" "$OUTPUT"
