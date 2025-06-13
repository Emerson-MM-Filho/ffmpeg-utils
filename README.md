# ffmpeg-scripts

This repository contains small utilities for working with `ffmpeg`.

## join_videos.sh

Use `join_videos.sh` to concatenate two video files. You can optionally specify a transition duration (in seconds):

```bash
./join_videos.sh input1.mp4 input2.mp4 output.mp4 [transition_duration]
```

Without a transition, the script uses the `ffmpeg` concat demuxer and does not re-encode the inputs. When a duration is provided, a crossfade is applied which re-encodes the output.

