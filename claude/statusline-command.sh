#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
model_name=$(echo "$input" | jq -r '.model.display_name')
output_style=$(echo "$input" | jq -r '.output_style.name')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# Calculate context window percentage (using current_usage, not cumulative totals)
usage=$(echo "$input" | jq '.context_window.current_usage')
context_pct=""
if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((current * 100 / size))
    context_pct=" ${pct}%"
fi

# Build left side (default Claude Code info)
left_side="${model_name}"
if [ -n "$output_style" ] && [ "$output_style" != "default" ]; then
    left_side="${left_side} | ${output_style}"
fi
if [ -n "$context_pct" ]; then
    left_side="${left_side} |${context_pct}"
fi
if [ -n "$vim_mode" ]; then
    left_side="${left_side} | ${vim_mode}"
fi

# Build right side (custom backend info)
# Extract git branch
branch=$(cd "$current_dir" 2>/dev/null && git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null)
repo_name=$(basename "$current_dir")
right_side="[BACKEND] ${repo_name}"
if [ -n "$branch" ]; then
    right_side="${right_side} | ${branch}"
fi

# Get terminal width and calculate spacing
terminal_width=$(tput cols 2>/dev/null || echo 80)
left_length=${#left_side}
right_length=${#right_side}
spaces_needed=$((terminal_width - left_length - right_length - 2))

# Ensure at least 2 spaces between left and right
if [ $spaces_needed -lt 2 ]; then
    spaces_needed=2
fi

# Print with spacing
printf "%s%${spaces_needed}s%s" "$left_side" "" "$right_side"
