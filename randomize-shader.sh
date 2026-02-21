#!/bin/bash
# Randomly pick a watercolor shader and symlink it as the active one.
# Add to your .zshrc: source ~/code/ghostty-shaders/randomize-shader.sh

SHADER_DIR="$HOME/code/ghostty-shaders"
LINK="$SHADER_DIR/active-shader.glsl"

shaders=(
    "$SHADER_DIR/flat-wash-bg.glsl"
    "$SHADER_DIR/graded-wash-bg.glsl"
    "$SHADER_DIR/variegated-wash-bg.glsl"
)

picked="${shaders[$((RANDOM % ${#shaders[@]}))]}"
ln -sf "$picked" "$LINK"
