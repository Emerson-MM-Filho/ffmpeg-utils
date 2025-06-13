# ffmpeg-scripts

This repository contains small utilities for working with `ffmpeg`.

## join_videos.sh

Use `join_videos.sh` to concatenate two video files. You can optionally specify
the length of a crossfade transition (in seconds). When a duration is
provided, the second video begins earlier so that the crossfade starts the full
duration before the first video ends and finishes exactly when it does:

```bash
./join_videos.sh input1.mp4 input2.mp4 output.mp4 [transition_duration]
```

Without a transition, the script uses the `ffmpeg` concat demuxer and does not re-encode the inputs. When a duration is provided, a crossfade is applied which re-encodes the output.

## scale_video.sh

Use `scale_video.sh` to resize a video by a given scaling factor. The script
takes the input video, a factor, and an optional output file. When the output
is omitted, a new file with `_scaled` appended to the original name is written:

```bash
./scale_video.sh input.mp4 0.5   # 50% of the original size
./scale_video.sh input.mp4 2     # 200% of the original size
```


