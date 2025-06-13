#!/usr/bin/env bash

# Script to scale a video's resolution by a given factor using ffmpeg.
# Usage: ./scale_video.sh input.mp4 factor [output]

set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <input> <scale_factor> [output]" >&2
    exit 1
fi

INPUT=$(realpath "$1")
SCALE=$2
OUTPUT="${3:-}"

# Derive output filename if not provided
if [ -z "$OUTPUT" ]; then
    EXT="${INPUT##*.}"
    BASENAME="${INPUT%.*}"
    OUTPUT="${BASENAME}_scaled.${EXT}"
fi

ffmpeg -i "$INPUT" -vf "scale=iw*${SCALE}:ih*${SCALE}" -c:a copy "$OUTPUT"

