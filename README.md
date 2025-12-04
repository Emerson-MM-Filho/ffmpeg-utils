# FFmpeg Utility Scripts

A collection of Bash scripts to simplify common video processing and streaming tasks using **FFmpeg**.

These scripts act as wrappers around complex FFmpeg commands, providing easy-to-use interfaces for concatenating videos with transitions, resizing media files, and streaming files to RTMP endpoints (specifically optimized for AWS IVS).

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

### 2. Resize Media (`resize.sh`)

Resizes images and videos to specified dimensions. Supports both single file and batch directory processing.

* **Aspect Ratio:** Automatically maintained when using presets or specifying `-1` for width/height
* **Formats:** Supports common video formats (mp4, mov, avi, mkv, webm) and images (jpg, png, webp, gif)
* **Batch Processing:** Recursively processes all media files in a directory with preserved folder structure

**Usage:**

```bash
./scripts/resize.sh [-e extension] <input_path> <size> [output_dir] [quality]
```

**Options:**

* `-e`: Output format/extension (e.g., `mp4`, `webm`, `jpg`, `png`) - Optional. If not specified, keeps original format

**Arguments:**

* `<input_path>`: Path to a video/image file or directory containing media files (required)
* `<size>`: Target size - presets (`720p`, `1080p`, `4k`, `thumb`) or dimensions (`1920x1080`, `1920:-1`, `-1:1080`) (required)
* `[output_dir]`: Output directory (optional, defaults to `./resized/`)
* `[quality]`: CRF value for videos - lower = better quality (optional, default: 23)

**Size Options:**

* **Presets:**
  * `720p` - 1280x720
  * `1080p` - 1920x1080
  * `4k` - 3840x2160
  * `thumb` - 320 pixels wide (aspect maintained)

* **Custom Dimensions:**
  * `1920x1080` - Exact dimensions (may distort if aspect ratio differs)
  * `1920:-1` - Width of 1920px, height auto-calculated to maintain aspect
  * `-1:1080` - Height of 1080px, width auto-calculated to maintain aspect

**Output Filenames:**

Files are saved with the pattern: `{original_name}_{size}.{extension}`

* Single file: `video.mp4` → `video_1080p.mp4`
* Custom dimensions: `photo.jpg` resized to `1920:-1` → `photo_1920x1080.jpg` (actual dimensions calculated)
* Directory: Preserves folder structure in output directory

**Examples:**

* **Resize single video to 1080p:**

    ```bash
    ./scripts/resize.sh video.mp4 1080p
    ```

* **Resize all media in a directory:**

    ```bash
    ./scripts/resize.sh ./my_videos/ 720p ./output/
    ```

* **Create thumbnails with custom quality:**

    ```bash
    ./scripts/resize.sh holiday.mp4 thumb ./thumbnails/ 20
    ```

* **Resize maintaining aspect ratio (1280px wide):**

    ```bash
    ./scripts/resize.sh presentation.mov 1280:-1
    ```

* **Batch process with folder structure preserved:**

    ```bash
    ./scripts/resize.sh ./media/ 1080p ./resized/
    # Input:  ./media/subfolder/video.mp4
    # Output: ./resized/subfolder/video_1080p.mp4
    ```

---

### 3. Stream to RTMP (`stream_file.sh`)

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
