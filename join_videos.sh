#!/usr/bin/env bash

# Script to concatenate two video files using ffmpeg.
# Usage: ./join_videos.sh input1.mp4 input2.mp4 output.mp4 [transition_duration]

set -euo pipefail

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <input1> <input2> <output> [transition_duration_sec]" >&2
    exit 1
fi

INPUT1=$(realpath "$1")
INPUT2=$(realpath "$2")
OUTPUT=$3
TRANSITION_DURATION="${4:-0}"

if [ "$TRANSITION_DURATION" = "0" ]; then
    # Simple concat without re-encoding
    LIST_FILE=$(mktemp)
    trap 'rm -f "$LIST_FILE"' EXIT
    printf "file '%s'\nfile '%s'\n" "$INPUT1" "$INPUT2" > "$LIST_FILE"
    ffmpeg -f concat -safe 0 -i "$LIST_FILE" -c copy "$OUTPUT"
else
    # Crossfade transition
    DUR1=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT1")
    OFFSET=$(awk -v d1="$DUR1" -v d="$TRANSITION_DURATION" 'BEGIN{print d1 - d/2}')
    ffmpeg -i "$INPUT1" -i "$INPUT2" \
        -filter_complex "[0:v][1:v]xfade=transition=fade:duration=${TRANSITION_DURATION}:offset=${OFFSET}[v];[0:a][1:a]acrossfade=d=${TRANSITION_DURATION}[a]" \
        -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset veryfast "$OUTPUT"
fi
