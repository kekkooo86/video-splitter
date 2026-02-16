# 🎬 Video Splitter

> Split long videos into segments with professional labels and automatic titles.
> Perfect for social media, video series, or any content that needs to be divided into shorter clips.

[![Docker
Hub](https://img.shields.io/docker/v/kekkooo86/video-splitter?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/kekkooo86/video-splitter)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

------------------------------------------------------------------------

## 🚀 Quick Start

### With Docker (Recommended)

``` bash
# Pull image
docker pull kekkooo86/video-splitter:latest

# Use
docker run -v $(pwd):/videos kekkooo86/video-splitter -i video.mp4 -T "Documentary|Italy"
```

### Locally

``` bash
# Clone
git clone https://github.com/kekkooo86/video-splitter.git
cd video-splitter

# Use
chmod +x split_video.sh
./split_video.sh -i video.mp4 -T "Title"
```

------------------------------------------------------------------------

## ✨ Features

-   ✂️ Split videos into segments (default 60s)
-   🏷️ Automatic "Part X" labels
-   🎨 Centered intro titles with fade effect
-   📱 Auto-detect aspect ratio (9:16, 16:9, 1:1)
-   ⏱️ Process specific time ranges (start/end)
-   ⚡ Parallel processing (up to 3 videos)
-   🧪 Test mode

------------------------------------------------------------------------

## 📋 Parameters

``` bash
./split_video.sh -i VIDEO [options]

Options:
  -i FILE       Video to process (required)
  -s SECONDS    Segment duration (default: 60, accepts float)
  -o SECONDS    Overlap (default: 5, accepts float)
  -S SECONDS    Start time (default: 0, accepts float)
  -E SECONDS    End time (default: video duration, accepts float)
  -T "TEXT"     Intro title (use | for line break)
  -l on/off     "Part X" label (default: on)
  -L "TEXT"     Custom label text (replaces "Part X")
  -p 1-3        Parallelism (default: 1)
  --test-first  Test only the first segment
```

------------------------------------------------------------------------

## 🎯 Examples

### Basic

``` bash
./split_video.sh -i documentary.mp4
```

### With title

``` bash
./split_video.sh -i documentary.mp4 -T "Southern|Documentary"
```

### Custom label instead of "Part X"

``` bash
./split_video.sh -i video.mp4 -L "Episodio 1" -T "Serie TV"
```

### Precise timing with float values

``` bash
# Split at 59.5 seconds with 2.5 seconds overlap
./split_video.sh -i video.mp4 -s 59.5 -o 2.5

# Process from 30.25s to 3 minutes and 15.75 seconds
./split_video.sh -i video.mp4 -S 30.25 -E 195.75
```

### Process specific time range

``` bash
# Process only from 30 seconds to 3 minutes
./split_video.sh -i video.mp4 -S 30 -E 180

# Process from 1 minute to end
./split_video.sh -i video.mp4 -S 60
```

### Parallel processing

``` bash
./split_video.sh -i video.mp4 -T "Series" -p 2
```

### Test first segment

``` bash
./split_video.sh -i video.mp4 -T "Test" --test-first
```

------------------------------------------------------------------------

## 🐳 Docker

### Pull from Docker Hub

``` bash
docker pull kekkooo86/video-splitter:latest
```

### Local build

``` bash
docker build -t video-splitter:1.3.0 .
```

### Use with your videos

**Basic usage:**
``` bash
# Mount your video directory to /videos in the container
docker run --rm \
  -v /path/to/your/videos:/videos \
  kekkooo86/video-splitter \
  -i your-video.mp4
```

**With custom label and title:**
``` bash
docker run --rm \
  -v /Users/kekko/Downloads:/videos \
  kekkooo86/video-splitter \
  -i video.mp4 \
  -L "Episodio 1" \
  -T "Serie TV"
```

**With float timing:**
``` bash
docker run --rm \
  -v $(pwd):/videos \
  kekkooo86/video-splitter \
  -i video.mp4 \
  -s 59.5 \
  -o 2.5 \
  -L "Part Custom"
```

### 📂 Output Location

The output folder is created **next to your original video file** in the mounted directory:

```
/path/to/your/videos/
├── your-video.mp4                    # Original file
└── your-video/                       # Output folder (created automatically)
    ├── your-video_parte_01.mp4
    ├── your-video_parte_02.mp4
    └── your-video_parte_03.mp4
```

**Example:**
```bash
# If your video is in /Users/kekko/Downloads/
docker run --rm -v /Users/kekko/Downloads:/videos kekkooo86/video-splitter -i myvideo.mp4

# Output will be in:
# /Users/kekko/Downloads/myvideo/myvideo_parte_01.mp4
# /Users/kekko/Downloads/myvideo/myvideo_parte_02.mp4
# etc.
```

------------------------------------------------------------------------


## 🔧 Requirements

-   **Docker** (recommended) or:
-   **FFmpeg 4.4+**
-   **Bash 4+**
-   **bc** (basic calculator)

------------------------------------------------------------------------

## 📝 Installation

### macOS

``` bash
brew install ffmpeg
```

### Linux (Ubuntu/Debian)

``` bash
sudo apt-get install ffmpeg bc
```

### Usage

``` bash
chmod +x split_video.sh
./split_video.sh -i video.mp4
```

------------------------------------------------------------------------

## ❓ FAQ

### Does the title appear in all video segments?

Yes! The title appears in **every segment** for the first N seconds (overlap duration, default 5s). This is because each segment starts with a fresh timeline at t=0.

### How does the overlap work?

Each segment overlaps with the previous one. For example:
- Segment 1: 0s → 60s
- Segment 2: 55s → 115s (5s overlap)
- Segment 3: 110s → 170s (5s overlap)

The title appears in the overlap section (first 5s) of each segment, providing continuity.

### Can I test only the first segment?

Yes! Use the `--test-first` flag:

```bash
./split_video.sh -i video.mp4 -T "Title" --test-first
```

This generates only the first segment, letting you verify settings before processing the entire video.

### Why use `-ss` before `-i`?

FFmpeg positioning matters! Using `-ss` before `-i` (input seeking) resets the timeline to t=0 for each segment, ensuring filters work correctly. This is faster and more reliable than output seeking.

------------------------------------------------------------------------

## 📄 License

MIT License - see [LICENSE](LICENSE)

------------------------------------------------------------------------

## 👤 Author

**kekkooo86** - Docker Hub:
[@kekkooo86](https://hub.docker.com/r/kekkooo86) - GitHub:
[@kekkooo86](https://github.com/kekkooo86)

------------------------------------------------------------------------

## 📁 Project Structure

```
video-splitter/
├── split_video.sh           # Main script (local use)
├── split_video_docker.sh    # Docker wrapper
├── split_video_core.sh      # Core functions (shared)
├── Dockerfile               # Docker image definition
├── docker-compose.yml       # Docker Compose config
├── LICENSE                  # MIT License
├── README.md               # This file
├── CONTRIBUTING.md         # Contribution guidelines
└── scripts/                # Utility scripts
    └── publish-docker.sh   # Publish to Docker Hub
```

------------------------------------------------------------------------

## 🔧 Requirements

-   [jrottenberg/ffmpeg](https://hub.docker.com/r/jrottenberg/ffmpeg) -
    Base Docker image
-   [Liberation
    Fonts](https://github.com/liberationfonts/liberation-fonts) - Font
    rendering

------------------------------------------------------------------------

**Created with ❤️ for content creators**
