# FFmpeg Utility Scripts

A collection of Bash scripts to simplify common video processing and streaming tasks using **FFmpeg**.

These scripts act as wrappers around complex FFmpeg commands, providing easy-to-use interfaces for concatenating videos with transitions and streaming files to RTMP endpoints (specifically optimized for AWS IVS).

## 🛠 Prerequisites

You need **FFmpeg** and **FFprobe** installed on your system.

### macOS (Homebrew)

```bash
brew install ffmpeg
```

### Linux (Debian/Ubuntu)

```bash
sudo apt update && sudo apt install ffmpeg
```

## 🚀 Installation

1. Clone or download this repository.
2. Make the scripts executable:

```bash
chmod +x scripts/*.sh
```

---

## 🎥 Scripts

### 1. Concatenate Videos (`concat.sh`)

Joins two video files together. It operates in two modes:

1. **Instant Join:** If no transition time is specified, it uses the `concat` demuxer to join files without re-encoding (extremely fast). *Note: Inputs must have the same codecs/resolution.*
2. **Crossfade:** If a duration is specified, it re-encodes the videos and applies a visual crossfade and audio crossfade.

**Usage:**

```bash
./scripts/concat.sh <input1> <input2> <output> [transition_duration]
```

**Examples:**

* **Simple Join (No Re-encoding):**

    ```bash
    ./scripts/concat.sh part1.mp4 part2.mp4 full_video.mp4
    ```

* **Join with 2-second Crossfade:**

    ```bash
    ./scripts/concat.sh intro.mp4 content.mp4 final.mp4 2
    ```

---

### 2. Stream to RTMP (`stream_file.sh`)

Streams a local video file to an RTMP endpoint.

* **GOP Size:** Fixed at 2 seconds (`-g 60 -keyint_min 60` @ 30fps).
* **Bitrate:** CBR-like settings (~4.5Mbps).
* **Looping:** Loops the video infinitely by default.

**Usage:**

```bash
./scripts/stream_file.sh -f <file_path> -u <rtmp_url> [-1]
```

**Arguments:**

* `-f`: Path to the local video file.
* `-u`: Full RTMP URL (Ingest Endpoint + Stream Key).
* `-1`: (Optional) Play the file once and stop (disables the default infinite loop).

**Examples:**

* **Stream indefinitely (Looping):**

    ```bash
    ./scripts/stream_file.sh \
      -f ./assets/sample.mp4 \
      -u rtmps://abc.global-contribute.live-video.net:443/app/sk_us-east-1_12345
    ```

* **Stream once:**

    ```bash
    ./scripts/stream_file.sh \
      -f ./assets/intro.mp4 \
      -u rtmps://abc.global-contribute.live-video.net:443/app/sk_us-east-1_12345 \
      -1
    ```

## 📝 License

See the [LICENSE](LICENSE) file for details.
