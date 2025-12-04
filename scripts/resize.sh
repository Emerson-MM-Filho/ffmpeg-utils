#!/usr/bin/env bash

# Script to resize images and videos using ffmpeg.
# Usage: ./resize.sh [-e extension] <input_path> <size> [output_dir] [quality]

set -euo pipefail

# Default values
OUTPUT_DIR="./resized"
QUALITY="23"
OUTPUT_EXT=""

# Usage function
usage() {
    echo "Usage: $0 [-e extension] <input_path> <size> [output_dir] [quality]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  -e          Optional output format/extension (e.g., mp4, webm, jpg, png)" >&2
    echo "              If not specified, keeps original format" >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  input_path  Path to a file or directory" >&2
    echo "  size        Preset (720p, 1080p, 4k, thumb) or dimensions (1920x1080, 1920:-1, -1:1080)" >&2
    echo "  output_dir  Optional output directory (default: ./resized)" >&2
    echo "  quality     Optional CRF value for videos (default: 23, lower = better quality)" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 video.mp4 1080p" >&2
    echo "  $0 ./videos/ 720p ./output/" >&2
    echo "  $0 photo.jpg thumb ./thumbnails/ 20" >&2
    echo "  $0 -e mp4 video.avi 1080p ./output/" >&2
    echo "  $0 -e jpg image.png 720p" >&2
    exit 1
}

# Parse optional flag
while getopts "e:" opt; do
    case $opt in
        e) OUTPUT_EXT="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

# Check arguments
if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    usage
fi

INPUT_PATH="$1"
SIZE="$2"
OUTPUT_DIR="${3:-$OUTPUT_DIR}"
QUALITY="${4:-$QUALITY}"

# Validate input exists
if [ ! -e "$INPUT_PATH" ]; then
    echo "❌ Error: Input path '$INPUT_PATH' does not exist." >&2
    exit 1
fi

# Check for ffmpeg and ffprobe
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ Error: ffmpeg is not installed." >&2
    exit 1
fi

if ! command -v ffprobe &> /dev/null; then
    echo "❌ Error: ffprobe is not installed." >&2
    exit 1
fi

# Map presets to dimensions
get_dimensions() {
    local size="$1"
    case "$size" in
        720p)   echo "1280:720" ;;
        1080p)  echo "1920:1080" ;;
        4k)     echo "3840:2160" ;;
        thumb)  echo "320:-1" ;;
        *)      echo "$size" | tr 'x' ':' ;;
    esac
}

# Get file type (image or video)
get_media_type() {
    local file="$1"
    local ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

    case "$ext" in
        mp4|mov|avi|mkv|webm|flv|wmv|m4v)
            echo "video" ;;
        jpg|jpeg|png|webp|gif|bmp|tiff)
            echo "image" ;;
        *)
            echo "unknown" ;;
    esac
}

# Calculate actual dimensions after scaling
calculate_actual_dimensions() {
    local input_file="$1"
    local scale_filter="$2"

    # Get original dimensions
    local width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$input_file" 2>/dev/null)
    local height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$input_file" 2>/dev/null)

    if [ -z "$width" ] || [ -z "$height" ]; then
        echo "unknown"
        return
    fi

    # Parse scale filter (format: width:height)
    IFS=':' read -r target_w target_h <<< "$scale_filter"

    # Calculate dimensions
    if [ "$target_w" = "-1" ] && [ "$target_h" != "-1" ]; then
        # Width is auto, height is fixed
        new_height="$target_h"
        new_width=$(awk -v w="$width" -v h="$height" -v th="$target_h" 'BEGIN{printf "%.0f", w * th / h}')
    elif [ "$target_h" = "-1" ] && [ "$target_w" != "-1" ]; then
        # Height is auto, width is fixed
        new_width="$target_w"
        new_height=$(awk -v w="$width" -v h="$height" -v tw="$target_w" 'BEGIN{printf "%.0f", h * tw / w}')
    elif [ "$target_w" = "-1" ] && [ "$target_h" = "-1" ]; then
        # Both auto (shouldn't happen, but fallback)
        new_width="$width"
        new_height="$height"
    else
        # Both dimensions specified
        new_width="$target_w"
        new_height="$target_h"
    fi

    # Make dimensions even (required for many video codecs)
    new_width=$(awk -v w="$new_width" 'BEGIN{printf "%.0f", int((w + 1) / 2) * 2}')
    new_height=$(awk -v h="$new_height" 'BEGIN{printf "%.0f", int((h + 1) / 2) * 2}')

    echo "${new_width}x${new_height}"
}

# Get size label for filename
get_size_label() {
    local size="$1"
    local input_file="$2"
    local dimensions=$(get_dimensions "$size")

    # If it's a preset, use the preset name
    case "$size" in
        720p|1080p|4k|thumb)
            echo "$size"
            return
            ;;
    esac

    # Calculate actual dimensions if -1 is used
    if [[ "$dimensions" == *"-1"* ]]; then
        local actual=$(calculate_actual_dimensions "$input_file" "$dimensions")
        if [ "$actual" != "unknown" ]; then
            echo "$actual"
            return
        fi
    fi

    # Use the dimensions as-is (replace : with x)
    echo "$dimensions" | tr ':' 'x'
}

# Resize a single file
resize_file() {
    local input_file="$1"
    local output_dir="$2"
    local size="$3"
    local quality="$4"
    local output_ext="$5"

    local media_type=$(get_media_type "$input_file")

    if [ "$media_type" = "unknown" ]; then
        echo "⚠️  Skipping (unsupported format): $input_file"
        return 1
    fi

    # Get dimensions for ffmpeg
    local dimensions=$(get_dimensions "$size")

    # Get size label for filename
    local size_label=$(get_size_label "$size" "$input_file")

    # Build output filename
    local filename=$(basename "$input_file")
    local name="${filename%.*}"
    local ext="${filename##*.}"

    # Use custom extension if provided, otherwise keep original
    if [ -n "$output_ext" ]; then
        ext="$output_ext"
    fi

    local output_file="${output_dir}/${name}_${size_label}.${ext}"

    # Create output directory if it doesn't exist
    mkdir -p "$output_dir"

    echo "🔄 Processing: $filename → ${name}_${size_label}.${ext}"

    # Determine target media type based on extension
    local target_type=$(get_media_type "dummy.$ext")

    # Resize based on target media type
    if [ "$target_type" = "video" ]; then
        ffmpeg -i "$input_file" \
            -vf "scale=${dimensions}" \
            -c:v libx264 \
            -crf "$quality" \
            -preset medium \
            -c:a copy \
            -y \
            "$output_file" 2>&1 | grep -E "frame=|error" || true
    else
        # For images, we don't use CRF
        ffmpeg -i "$input_file" \
            -vf "scale=${dimensions}" \
            -y \
            "$output_file" 2>&1 | grep -E "frame=|error" || true
    fi

    if [ $? -eq 0 ]; then
        echo "✅ Completed: ${name}_${size_label}.${ext}"
        return 0
    else
        echo "❌ Failed: $filename"
        return 1
    fi
}

# Process directory recursively
process_directory() {
    local input_dir="$1"
    local output_base="$2"
    local size="$3"
    local quality="$4"
    local output_ext="$5"

    # Find all media files
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$input_dir" -type f \( \
        -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o \
        -iname "*.webm" -o -iname "*.flv" -o -iname "*.wmv" -o -iname "*.m4v" -o \
        -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o \
        -iname "*.gif" -o -iname "*.bmp" -o -iname "*.tiff" \
    \) -print0)

    local total=${#files[@]}

    if [ "$total" -eq 0 ]; then
        echo "⚠️  No media files found in '$input_dir'"
        exit 0
    fi

    echo "📁 Found $total media file(s) in '$input_dir'"
    echo "================================================================"

    local count=0
    local success=0
    local failed=0

    for file in "${files[@]}"; do
        count=$((count + 1))
        echo ""
        echo "[$count/$total]"

        # Preserve directory structure
        local rel_dir=$(dirname "${file#$input_dir/}")
        if [ "$rel_dir" = "." ]; then
            local output_dir="$output_base"
        else
            local output_dir="$output_base/$rel_dir"
        fi

        if resize_file "$file" "$output_dir" "$size" "$quality" "$output_ext"; then
            success=$((success + 1))
        else
            failed=$((failed + 1))
        fi
    done

    echo ""
    echo "================================================================"
    echo "✅ Success: $success | ❌ Failed: $failed | 📊 Total: $total"
}

# Main execution
echo "================================================================"
echo "🎬 FFmpeg Media Resizer"
echo "================================================================"
echo "📂 Input:   $INPUT_PATH"
echo "📐 Size:    $SIZE"
echo "📁 Output:  $OUTPUT_DIR"
echo "🎯 Quality: $QUALITY (CRF for videos)"
if [ -n "$OUTPUT_EXT" ]; then
    echo "🔄 Format:  .$OUTPUT_EXT"
fi
echo "================================================================"
echo ""

if [ -f "$INPUT_PATH" ]; then
    # Single file
    INPUT_PATH=$(realpath "$INPUT_PATH")
    resize_file "$INPUT_PATH" "$OUTPUT_DIR" "$SIZE" "$QUALITY" "$OUTPUT_EXT"
    echo ""
    echo "✅ Done! Output saved to: $OUTPUT_DIR"
elif [ -d "$INPUT_PATH" ]; then
    # Directory
    INPUT_PATH=$(realpath "$INPUT_PATH")
    process_directory "$INPUT_PATH" "$OUTPUT_DIR" "$SIZE" "$QUALITY" "$OUTPUT_EXT"
    echo ""
    echo "✅ Done! All files saved to: $OUTPUT_DIR"
else
    echo "❌ Error: '$INPUT_PATH' is neither a file nor a directory." >&2
    exit 1
fi
