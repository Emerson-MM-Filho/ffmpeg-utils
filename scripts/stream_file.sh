#!/bin/bash

# Default behavior
LOOP_FLAG="-stream_loop -1" # Default to infinite loop

# Function: Usage Help
usage() {
    echo "Usage: $0 -f <file_path> -u <full_rtmp_url> [-1]"
    echo ""
    echo "Arguments:"
    echo "  -f   Path to the local video file (Required)"
    echo "  -u   Full RTMP URL (Ingest Endpoint + Stream Key combined) (Required)"
    echo "       Example: rtmps://xyz.global-contribute.live-video.net:443/app/sk_us-east-1_123"
    echo "  -1   Play once and stop (Disable infinite looping)"
    echo ""
    exit 1
}

# Parse Command Line Arguments
while getopts "f:u:1" opt; do
  case $opt in
    f) FILE_PATH="$OPTARG" ;;
    u) TARGET_URL="$OPTARG" ;;
    1) LOOP_FLAG="" ;; # Clear loop flag if -1 is passed
    *) usage ;;
  esac
done

# Validation
if [ -z "$FILE_PATH" ] || [ -z "$TARGET_URL" ]; then
    echo "❌ Error: Missing required arguments."
    usage
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "❌ Error: File '$FILE_PATH' does not exist."
    exit 1
fi

echo "----------------------------------------------------------------"
echo "🎥 Input File: $FILE_PATH"
echo "📡 Target:     $TARGET_URL"
echo "🔄 Looping:    $( [ -z "$LOOP_FLAG" ] && echo "No" || echo "Yes" )"
echo "----------------------------------------------------------------"
echo "Starting Stream (Press 'q' to stop)..."

# FFmpeg Command
ffmpeg \
    -re \
    $LOOP_FLAG \
    -i "$FILE_PATH" \
    -c:v libx264 \
    -profile:v main \
    -preset veryfast \
    -tune zerolatency \
    -b:v 4500k \
    -maxrate 4500k \
    -bufsize 9000k \
    -pix_fmt yuv420p \
    -g 60 \
    -keyint_min 60 \
    -sc_threshold 0 \
    -c:a aac \
    -b:a 128k \
    -ar 44100 \
    -f flv \
    "$TARGET_URL"

echo "Stream Ended."
