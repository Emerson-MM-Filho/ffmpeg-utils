# Stream File Script Technical Documentation

The `stream_file.sh` transforms a static local file into a compliant live stream.

```bash
ffmpeg \
    -re \
    -stream_loop -1 \
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
```

## 1. Input Handling

| Flag | Explanation |
| :--- | :--- |
| **`-re`** | **Read at native frame rate.** Without this, FFmpeg would read the file as fast as the CPU allows (e.g., 300fps), causing the RTMP server to reject the connection immediately. This simulates "live" timing. |
| **`-stream_loop -1`** | Loops the input file infinitely. |

## 2. Latency & Encoding Speed

| Flag | Explanation |
| :--- | :--- |
| **`-preset veryfast`** | Uses less CPU to compress frames. Essential for live streaming to prevent "Encoding Overloaded" errors. |
| **`-tune zerolatency`** | Disables internal frame buffering and lookahead. This ensures frames are sent to the network immediately, reducing the delay between "source" and "viewer." |

## 3. Network Stability (Bitrate)

Streaming requires a flat, predictable pipe. We use **CBR (Constant Bitrate)** settings to prevent network congestion.

| Flag | Explanation |
| :--- | :--- |
| **`-b:v 4500k`** | Target Video Bitrate (4.5 Mbps). |
| **`-maxrate 4500k`** | **Hard Cap.** The encoder is strictly forbidden from exceeding 4.5 Mbps, even during complex scenes (like explosions). This prevents buffering for viewers with slower internet. |
| **`-bufsize 9000k`** | The "Token Bucket" size. Setting this to 2x the maxrate is a standard practice that gives the encoder just enough flexibility to maintain quality while strictly adhering to the maxrate average. |

## 4. Platform Compatibility (GOP Structure)

AWS IVS requires a strict Keyframe interval to generate HLS segments correctly.

| Flag | Explanation |
| :--- | :--- |
| **`-g 60`** | **Group of Pictures (GOP)** size. At 30fps, 60 frames equals exactly **2 seconds**. |
| **`-keyint_min 60`** | Forces the minimum interval to also be 60. This prevents the encoder from inserting extra keyframes. |
| **`-sc_threshold 0`** | **Scene Cut Threshold.** Disables the encoder's ability to detect scene changes and insert random keyframes. We want keyframes purely on the 2-second grid, regardless of video content. |
| **`-pix_fmt yuv420p`** | Ensures the color space is compatible with all players (browsers/phones). Some inputs might be 4:2:2 or 4:4:4, which won't play on the web. |

## 5. Audio & Output

| Flag | Explanation |
| :--- | :--- |
| **`-c:a aac`** | Advanced Audio Coding (Standard for FLV/RTMP). |
| **`-ar 44100`** | Audio Sample Rate (44.1kHz). |
| **`-f flv`** | **Flash Video container.** Required for RTMP streaming. |
