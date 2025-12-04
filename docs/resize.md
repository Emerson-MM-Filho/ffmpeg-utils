# Resize Script Technical Documentation

The `resize.sh` script resizes images and videos using FFmpeg's `scale` filter, with support for both single files and batch directory processing.

## Core FFmpeg Command

### For Videos

```bash
ffmpeg -i "$input_file" \
    -vf "scale=${dimensions}" \
    -c:v libx264 \
    -crf "$quality" \
    -preset medium \
    -c:a copy \
    -y \
    "$output_file"
```

### For Images

```bash
ffmpeg -i "$input_file" \
    -vf "scale=${dimensions}" \
    -y \
    "$output_file"
```

---

## 1. Scale Filter Logic

The `scale` filter is FFmpeg's core resizing mechanism. It accepts dimensions in the format `width:height`.

### Preset Mappings

| Preset | Dimensions | Notes |
| :--- | :--- | :--- |
| **`720p`** | `1280:720` | Standard HD |
| **`1080p`** | `1920:1080` | Full HD |
| **`4k`** | `3840:2160` | Ultra HD |
| **`thumb`** | `320:-1` | Thumbnail width, height auto-calculated |

### Dynamic Aspect Ratio with `-1`

The `-1` value tells FFmpeg to **automatically calculate** that dimension to maintain the original aspect ratio.

**Examples:**

* `scale=1920:-1` - Width fixed at 1920px, height calculated proportionally
* `scale=-1:1080` - Height fixed at 1080px, width calculated proportionally
* `scale=1920:1080` - Both dimensions fixed (may distort if aspect ratio differs)

### Even Dimension Rounding

Most video codecs (especially H.264) require dimensions to be **even numbers**. The script automatically rounds calculated dimensions:

```bash
new_width=$(awk -v w="$new_width" 'BEGIN{printf "%.0f", int((w + 1) / 2) * 2}')
```

This ensures compatibility across all players and platforms.

---

## 2. Dimension Calculation for Filenames

When using `-1` in dimensions, the script calculates the actual output size to create meaningful filenames.

### Process:

1. **Read original dimensions** using `ffprobe`:
   ```bash
   ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$input_file"
   ```

2. **Calculate new dimensions** based on aspect ratio:
   ```bash
   # Example: Input is 1920x1080, target is 1280:-1
   new_height = original_height * (target_width / original_width)
   new_height = 1080 * (1280 / 1920) = 720
   ```

3. **Generate filename** with actual dimensions:
   ```
   video_1280x720.mp4
   ```

---

## 3. Video Encoding Settings

### Quality Control (CRF)

| Flag | Explanation |
| :--- | :--- |
| **`-c:v libx264`** | Encodes video using H.264 codec (universal compatibility). |
| **`-crf 23`** | **Constant Rate Factor** (default). Lower values = higher quality/larger files. Range: 0-51. Recommended: 18 (visually lossless) to 28 (acceptable quality). |
| **`-preset medium`** | Balances encoding speed vs compression efficiency. Options: `ultrafast`, `fast`, `medium`, `slow`, `veryslow`. |

### Audio Handling

| Flag | Explanation |
| :--- | :--- |
| **`-c:a copy`** | **Stream copy** for audio. No re-encoding, preserves original audio quality. Fast and lossless. |

**Why stream copy?** Resizing only affects video frames. Audio data is independent of resolution, so there's no need to re-encode it.

---

## 4. Image Processing

For images, the script uses a simplified command:

```bash
ffmpeg -i "$input_file" -vf "scale=${dimensions}" -y "$output_file"
```

**Key differences:**

* No CRF (quality is inherent to the image format)
* No audio stream handling
* No encoding presets needed
* FFmpeg auto-detects output format from file extension

**Supported formats:** JPG, PNG, WebP, GIF, BMP, TIFF

---

## 5. Batch Processing

### File Discovery

The script uses `find` to recursively locate all media files:

```bash
find "$input_dir" -type f \( \
    -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o \
    -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \
\) -print0
```

* **`-type f`**: Files only (excludes directories)
* **`-iname`**: Case-insensitive pattern matching
* **`-print0`**: Null-terminated output (handles filenames with spaces)

### Directory Structure Preservation

When processing directories, the script maintains the folder hierarchy:

```bash
# Calculate relative path from input directory
rel_dir=$(dirname "${file#$input_dir/}")

# Reconstruct in output directory
output_dir="$output_base/$rel_dir"
```

**Example:**

```
Input:  ./media/vacation/day1/video.mp4
Output: ./resized/vacation/day1/video_1080p.mp4
```

---

## 6. Error Handling

### Per-File Error Tolerance

The script uses `|| true` to prevent batch processing from stopping on single file failures:

```bash
ffmpeg ... 2>&1 | grep -E "frame=|error" || true
```

This ensures that one corrupt or incompatible file doesn't halt the entire batch.

### File Type Detection

Media type is determined by file extension:

```bash
case "$ext" in
    mp4|mov|avi|mkv|webm) echo "video" ;;
    jpg|jpeg|png|webp) echo "image" ;;
    *) echo "unknown" ;;
esac
```

Files with unsupported extensions are skipped with a warning.

---

## 7. Performance Considerations

### Video vs Image Processing Speed

| Media Type | Speed | Reason |
| :--- | :--- | :--- |
| **Images** | Instant (< 1s) | Single frame processing |
| **Videos** | Slower (depends on length) | Must re-encode every frame at the new resolution |

### CRF Impact on Speed

Lower CRF values (higher quality) take slightly longer to encode, but the impact is minimal compared to the preset choice.

### Preset vs Quality Tradeoff

| Preset | Speed | File Size | Use Case |
| :--- | :--- | :--- | :--- |
| **ultrafast** | Fastest | Largest | Quick previews |
| **medium** | Balanced | Normal | General use (default) |
| **slow** | Slow | Smallest | Archival/distribution |

---

## 8. Output Filename Pattern

The script generates filenames following this pattern:

```
{original_name}_{size_label}.{extension}
```

### Size Label Generation

1. **Presets**: Use preset name directly
   * `video.mp4` + `1080p` → `video_1080p.mp4`

2. **Explicit dimensions**: Use as-is
   * `photo.jpg` + `1920x1080` → `photo_1920x1080.jpg`

3. **Auto-calculated dimensions**: Calculate and use actual values
   * `video.mp4` (1920x1080) + `1280:-1` → `video_1280x720.mp4`

This ensures filenames always reflect the true output dimensions.
