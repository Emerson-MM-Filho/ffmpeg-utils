# Concatenation Script Technical Documentation

The `concat.sh` script employs two completely different FFmpeg strategies depending on whether a transition duration is provided.

## 1. Mode A: Instant Join (No Re-encoding)

When `TRANSITION_DURATION` is 0, the script uses the **Concat Demuxer**.

```bash
ffmpeg -f concat -safe 0 -i "$LIST_FILE" -c copy "$OUTPUT"
```

### 🔍 Command Breakdown

| Flag | Description |
| :--- | :--- |
| **`-f concat`** | Forces the input format to be the "Virtual Concatenation Script" format. |
| **`-safe 0`** | Allows FFmpeg to accept absolute file paths in the list file (required for script portability). |
| **`-i "$LIST_FILE"`** | The input is a text file containing the list of videos to join (e.g., `file '/path/to/vid1.mp4'`). |
| **`-c copy`** | **Stream Copy**. This is the most important flag. It tells FFmpeg to copy the video and audio data packets directly from input to output **without decoding or re-encoding**. |

* **Result:** Extremely fast operation (limited only by disk speed).
* **Limitation:** Inputs must have identical resolution, frame rates, and codecs.

---

## 2. Mode B: Crossfade Transition (Re-encoding)

When a duration is provided, the script uses **Filter Complex** graphs to render a new video.

```bash
ffmpeg -i "$INPUT1" -i "$INPUT2" \
    -filter_complex "[0:v][1:v]xfade=transition=fade:duration=${TRANSITION_DURATION}:offset=${OFFSET}[v];[0:a][1:a]acrossfade=d=${TRANSITION_DURATION}[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset veryfast "$OUTPUT"
```

### 🧮 The Offset Logic

Transitions work by overlapping two videos. Video 2 must start playing *before* Video 1 ends.
The script calculates the offset using `awk`:
> **Offset = (Duration of Video 1) - (Transition Duration)**

### 🔍 Command Breakdown (Filter Complex)

#### Visual Filter (`xfade`)

`[0:v][1:v]xfade=transition=fade:duration=...:offset=...[v]`

* **`[0:v][1:v]`**: Takes Video Stream 0 and Video Stream 1 as inputs.
* **`transition=fade`**: The mathematical blending mode (standard opacity fade).
* **`offset`**: Time (in seconds) where the second video begins to appear.
* **`[v]`**: Labels the result of this operation as "v" to be mapped later.

#### Audio Filter (`acrossfade`)

`[0:a][1:a]acrossfade=d=...[a]`

* Applies a crossfade to the audio streams so the sound mixes smoothly alongside the video fade.

#### Encoding Settings

Since we are modifying pixels (fading), we **must** re-encode the video.

* **`-c:v libx264`**: Encodes using the H.264 standard.
* **`-crf 18`**: **Constant Rate Factor**. A value of 18 is often considered "visually lossless." (Lower is better quality, higher is smaller file size).
* **`-preset veryfast`**: Balances compression speed vs. efficiency.
