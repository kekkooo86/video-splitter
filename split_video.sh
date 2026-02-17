#!/bin/bash

# Video Splitter - Universal Version
# Works both locally (using Docker for ffmpeg) and inside Docker container

set -e

# Load shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/split_video_core.sh"

# Auto-detect environment: Docker container or local
if [ -f "/.dockerenv" ] || [ -n "$DOCKER_CONTAINER" ]; then
  # Running inside Docker container
  RUNNING_IN_DOCKER=true
  VIDEO_DIR="/videos"
  FFMPEG_CMD="ffmpeg"
else
  # Running locally, use Docker for ffmpeg
  RUNNING_IN_DOCKER=false
  VIDEO_DIR="."
  FFMPEG_CMD="docker run --rm -v VIDEO_DIR_PLACEHOLDER:/videos jrottenberg/ffmpeg"
fi

# Helper to build ffmpeg command with correct paths
build_ffmpeg_cmd() {
  if [ "$RUNNING_IN_DOCKER" = true ]; then
    echo "ffmpeg"
  else
    echo "$FFMPEG_CMD" | sed "s|VIDEO_DIR_PLACEHOLDER|$(cd "$VIDEO_DIR" && pwd)|g"
  fi
}

# Wrapper to call ffmpeg with correct paths
run_ffmpeg() {
  if [ "$RUNNING_IN_DOCKER" = true ]; then
    # Inside Docker: use ffmpeg directly
    ffmpeg "$@"
  else
    # Local: use Docker to run ffmpeg
    local video_dir_abs=$(cd "$VIDEO_DIR" && pwd)
    docker run --rm -v "$video_dir_abs:/videos" \
      -e FONTCONFIG_FILE=/dev/null \
      jrottenberg/ffmpeg "$@"
  fi
}

# Default values
SEGMENT_DURATION=60
OVERLAP=5
INPUT_FILE=""
INTERACTIVE=false
ADD_LABEL="on"
CUSTOM_LABEL=""
TITLE_TEXT=""
MAX_PARALLEL=1
TEST_FIRST=false
START_TIME=0
END_TIME=-1  # -1 significa "fino alla fine"
CROP_TOP=0
CROP_BOTTOM=0
CROP_LEFT=0
CROP_RIGHT=0

# If no arguments, use interactive mode
if [ $# -eq 0 ]; then
  INTERACTIVE=true
fi

# Parse arguments
while getopts "i:d:s:o:l:L:T:p:S:E:h-:" opt; do
  case $opt in
    i) INPUT_FILE="$OPTARG" ;;
    d) VIDEO_DIR="$OPTARG" ;;
    s) SEGMENT_DURATION="$OPTARG" ;;
    o) OVERLAP="$OPTARG" ;;
    l) ADD_LABEL="$OPTARG" ;;
    L) CUSTOM_LABEL="$OPTARG" ;;
    T) TITLE_TEXT="$OPTARG" ;;
    p) MAX_PARALLEL="$OPTARG" ;;
    S) START_TIME="$OPTARG" ;;
    E) END_TIME="$OPTARG" ;;
    h)
      echo "Usage: $0 [options]"
      echo ""
      echo "Without options: interactive mode"
      echo ""
      echo "Options:"
      echo "  -i  Video file name"
      echo "  -d  Directory containing the video (default: .)"
      echo "  -s  Duration of each segment in seconds (default: 60, accepts float)"
      echo "  -o  Overlap between segments in seconds (default: 5, accepts float)"
      echo "  -l  Add permanent 'Part X' label (on/off, default: on)"
      echo "  -L  Custom label text (replaces 'Part X' with your text)"
      echo "  -T  Intro title (use \| for line break)"
      echo "  -p  Number of parallel processes (default: 1, max: 3)"
      echo "  -S  Start time in seconds (default: 0, accepts float)"
      echo "  -E  End time in seconds (default: video duration, accepts float)"
      echo "  --crop-top N     Crop N pixels from top"
      echo "  --crop-bottom N  Crop N pixels from bottom"
      echo "  --crop-left N    Crop N pixels from left"
      echo "  --crop-right N   Crop N pixels from right"
      echo "  --test-first     Test only the first video"
      echo "  -h  Show this help"
      echo ""
      echo "Examples:"
      echo "  $0 -i documentary.mp4 -s 60 -o 5 -T \"Documentary South 1992\""
      echo "  $0 -i video.mp4 -T \"Series PIPE Episode 1\" -p 2"
      echo "  $0 -i video.mp4 -S 30 -E 180  # Process only from 30s to 180s"
      echo "  $0 -i video.mp4 -s 59.5 -o 2.5 -L \"Episodio 1\"  # Float times with custom label"
      echo "  $0 -i video.mp4 --crop-top 100 --crop-bottom 100  # Crop 100px from top and bottom"
      exit 0
      ;;
    -)
      case "${OPTARG}" in
        test-first) TEST_FIRST=true ;;
        crop-top) CROP_TOP="${!OPTIND}"; OPTIND=$((OPTIND + 1)) ;;
        crop-bottom) CROP_BOTTOM="${!OPTIND}"; OPTIND=$((OPTIND + 1)) ;;
        crop-left) CROP_LEFT="${!OPTIND}"; OPTIND=$((OPTIND + 1)) ;;
        crop-right) CROP_RIGHT="${!OPTIND}"; OPTIND=$((OPTIND + 1)) ;;
        *) echo "Invalid option: --${OPTARG}" >&2; exit 1 ;;
      esac
      ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
  esac
done

# Interactive mode
if [ "$INTERACTIVE" = true ]; then
  clear
  echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║    Video Splitter - Interactive Mode      ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
  echo ""

  echo -e "${YELLOW}1. Select video directory${NC}"
  echo -e "   Current directory: ${GREEN}$VIDEO_DIR${NC}"
  read -p "   Press ENTER to use this, or enter a new path: " new_dir
  [ -n "$new_dir" ] && VIDEO_DIR="$new_dir"

  if [ ! -d "$VIDEO_DIR" ]; then
    echo -e "${RED}Error: directory does not exist!${NC}"
    exit 1
  fi

  echo ""
  echo -e "${YELLOW}2. Choose video file${NC}"
  echo -e "   Files available in ${GREEN}$VIDEO_DIR${NC}:"
  echo ""

  videos=($(ls "$VIDEO_DIR"/*.{mp4,mov,avi,mkv,MP4,MOV,AVI,MKV} 2>/dev/null | xargs -n 1 basename))

  if [ ${#videos[@]} -eq 0 ]; then
    echo -e "${RED}   No video files found!${NC}"
    exit 1
  fi

  for i in "${!videos[@]}"; do
    echo -e "   ${GREEN}$((i+1)).${NC} ${videos[$i]}"
  done

  echo ""
  read -p "   Choose file number: " file_choice

  if [[ "$file_choice" =~ ^[0-9]+$ ]] && [ "$file_choice" -ge 1 ] && [ "$file_choice" -le "${#videos[@]}" ]; then
    INPUT_FILE="${videos[$((file_choice-1))]}"
  else
    INPUT_FILE="$file_choice"
  fi

  echo ""
  echo -e "${YELLOW}3. Configure parameters${NC}"
  read -p "   Segment duration [60]: " seg_input
  [ -n "$seg_input" ] && SEGMENT_DURATION="$seg_input"

  read -p "   Overlap [5]: " ovr_input
  [ -n "$ovr_input" ] && OVERLAP="$ovr_input"

  echo ""
  echo -e "${YELLOW}4. Labels and titles${NC}"
  read -p "   'Part X' label (y/n) [y]: " label_input
  [ "$label_input" = "n" ] && ADD_LABEL="off"

  read -p "   Intro title (leave empty for none): " title_input
  [ -n "$title_input" ] && TITLE_TEXT="$title_input"

  if [ "$ADD_LABEL" = "on" ] || [ -n "$TITLE_TEXT" ]; then
    echo ""
    echo -e "${YELLOW}5. Encoding${NC}"
    read -p "   Parallel processes (1-3) [1]: " parallel_input
    [[ "$parallel_input" =~ ^[1-3]$ ]] && MAX_PARALLEL="$parallel_input"

    read -p "   Test only first video? (y/n) [n]: " test_input
    [ "$test_input" = "s" ] && TEST_FIRST=true
  fi

  echo ""
  echo -e "${GREEN}✓ Configuration complete!${NC}"
  echo ""
fi

# Verify file
if [ -z "$INPUT_FILE" ]; then
  echo -e "${RED}Error: you must specify a video file${NC}"
  exit 1
fi

# Handle paths
if [[ "$INPUT_FILE" == /* ]]; then
  VIDEO_PATH="$INPUT_FILE"
  VIDEO_DIR=$(dirname "$INPUT_FILE")
  INPUT_FILE=$(basename "$INPUT_FILE")
else
  VIDEO_PATH="$VIDEO_DIR/$INPUT_FILE"
fi

if [ ! -f "$VIDEO_PATH" ]; then
  echo -e "${RED}Error: file $VIDEO_PATH does not exist${NC}"
  exit 1
fi

FILENAME="${INPUT_FILE%.*}"
EXTENSION="${INPUT_FILE##*.}"

OUTPUT_DIR="$VIDEO_DIR/$FILENAME"
if [ ! -d "$OUTPUT_DIR" ]; then
  mkdir -p "$OUTPUT_DIR"
  echo -e "${GREEN}✓ Created folder: $FILENAME${NC}"
else
  echo -e "${YELLOW}⚠ Folder $FILENAME already exists${NC}"
fi
echo ""

echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}📹 File:${NC} $INPUT_FILE"
echo -e "${GREEN}📁 Input directory:${NC} $VIDEO_DIR"
echo -e "${GREEN}📂 Output folder:${NC} $FILENAME/"
echo -e "${GREEN}⏱️  Segment duration:${NC} $SEGMENT_DURATION seconds"
echo -e "${GREEN}🔄 Overlap:${NC} $OVERLAP seconds"
float_gt $START_TIME 0 && echo -e "${GREEN}▶️  Start time:${NC} $START_TIME seconds"
[ "$END_TIME" != "-1" ] && float_lt $END_TIME 999999 && echo -e "${GREEN}⏹️  End time:${NC} $END_TIME seconds"
[ "$CROP_TOP" -gt 0 ] && echo -e "${GREEN}✂️  Crop top:${NC} $CROP_TOP pixels"
[ "$CROP_BOTTOM" -gt 0 ] && echo -e "${GREEN}✂️  Crop bottom:${NC} $CROP_BOTTOM pixels"
[ "$CROP_LEFT" -gt 0 ] && echo -e "${GREEN}✂️  Crop left:${NC} $CROP_LEFT pixels"
[ "$CROP_RIGHT" -gt 0 ] && echo -e "${GREEN}✂️  Crop right:${NC} $CROP_RIGHT pixels"
[ "$ADD_LABEL" = "on" ] && echo -e "${GREEN}🏷️  Permanent label:${NC} Enabled"
[ -n "$CUSTOM_LABEL" ] && echo -e "${GREEN}🏷️  Custom label:${NC} $CUSTOM_LABEL"
[ -n "$TITLE_TEXT" ] && echo -e "${GREEN}📝 Intro title:${NC} $TITLE_TEXT"
[ "$TEST_FIRST" = true ] && echo -e "${YELLOW}🧪 TEST: First video only${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Interactive confirmation
if [ "$INTERACTIVE" = true ]; then
  read -p "Proceed? (y/n): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "s" ]; then
    echo -e "${YELLOW}Operation cancelled.${NC}"
    exit 0
  fi
  echo ""
fi

# Analyze video
echo -e "${YELLOW}⏳ Analyzing video...${NC}"

# Specific wrapper for detect_aspect_ratio (uses Docker)
VIDEO_ASPECT="horizontal"
if [ "$ADD_LABEL" = "on" ] || [ -n "$TITLE_TEXT" ]; then
  VIDEO_ASPECT=$(detect_aspect_ratio "/videos/$(basename "$INPUT_FILE")" "run_ffmpeg")
fi

# Wrapper for get_video_duration (uses Docker)
DURATION=$(get_video_duration "/videos/$(basename "$INPUT_FILE")" "run_ffmpeg")
if [ -z "$DURATION" ]; then
  echo -e "${RED}Error: unable to get video duration${NC}"
  exit 1
fi

# Set END_TIME to video duration if not specified
if [ "$END_TIME" = "-1" ]; then
  END_TIME=$DURATION
fi

# Validate START_TIME and END_TIME
if float_lt $START_TIME 0; then
  echo -e "${RED}Error: Start time cannot be negative${NC}"
  exit 1
fi

if float_gt $END_TIME $DURATION; then
  echo -e "${YELLOW}⚠️  Warning: End time ($END_TIME s) exceeds video duration ($DURATION s)${NC}"
  echo -e "${YELLOW}   Using video duration instead${NC}"
  END_TIME=$DURATION
fi

if float_ge $START_TIME $END_TIME; then
  echo -e "${RED}Error: Start time ($START_TIME s) must be less than end time ($END_TIME s)${NC}"
  exit 1
fi

# Pre-processing: trim video if START_TIME or END_TIME are specified
CLEANUP_TEMP=false
ORIGINAL_INPUT_FILE="$INPUT_FILE"
ORIGINAL_VIDEO_PATH="$VIDEO_PATH"

if float_gt $START_TIME 0 || float_lt $END_TIME $DURATION; then
  echo -e "${YELLOW}🔧 Pre-processing: trimming video from ${START_TIME}s to ${END_TIME}s...${NC}"

  TEMP_VIDEO="${FILENAME}_temp_trimmed.${EXTENSION}"
  TEMP_VIDEO_PATH="$VIDEO_DIR/$TEMP_VIDEO"

  # Use stream copy for fast trimming (no re-encoding)
  START_TIME_FMT=$(format_time $START_TIME)
  TRIM_DURATION=$(float_sub $END_TIME $START_TIME)

  run_ffmpeg \
    -ss "$START_TIME_FMT" \
    -i "/videos/$(basename "$INPUT_FILE")" \
    -t "$TRIM_DURATION" \
    -c copy \
    "/videos/$TEMP_VIDEO" \
    -loglevel error -stats -y 2>&1 | grep -v "frame=" || true

  if [ $? -eq 0 ] && [ -f "$TEMP_VIDEO_PATH" ]; then
    echo -e "${GREEN}✓ Trimmed video created (stream copy, no re-encoding)${NC}"
    INPUT_FILE="$TEMP_VIDEO"
    VIDEO_PATH="$TEMP_VIDEO_PATH"
    CLEANUP_TEMP=true
    # Update duration to trimmed video duration
    DURATION=$TRIM_DURATION
  else
    echo -e "${RED}Error: Failed to create trimmed video${NC}"
    exit 1
  fi
  echo ""
fi

ESTIMATED_PARTS=$(float_int $(float_add $(float_div $(float_sub $DURATION $OVERLAP) $(float_sub $SEGMENT_DURATION $OVERLAP)) 1))
PADDING_LENGTH=${#ESTIMATED_PARTS}

echo -e "${GREEN}✓ Total duration: $DURATION seconds${NC}"
echo -e "${GREEN}✓ Parts to create: approximately $ESTIMATED_PARTS${NC}"
[ "$ADD_LABEL" = "on" ] || [ -n "$TITLE_TEXT" ] && echo -e "${GREEN}✓ Aspect ratio: $VIDEO_ASPECT${NC}"
echo ""

# Calculate segments
declare -a VIDEO_SEGMENTS=()
START=0
PART=1
SKIP_LAST=false

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Starting segment creation         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

while float_lt $START $DURATION; do
  END=$(float_add $START $SEGMENT_DURATION)
  float_gt $END $DURATION && END=$DURATION

  NEXT_START=$(float_sub $END $OVERLAP)
  REMAINING=$(float_sub $DURATION $NEXT_START)

  if float_gt $REMAINING 0 && float_lt $REMAINING $(float_div $SEGMENT_DURATION 2); then
    if [ "$INTERACTIVE" = true ]; then
      handle_short_final_segment $REMAINING $SEGMENT_DURATION && SKIP_LAST=false || SKIP_LAST=true
      [ "$SKIP_LAST" = true ] && END=$DURATION
    fi
  fi

  VIDEO_SEGMENTS+=("$START:$END:$PART")

  [ "$SKIP_LAST" = true ] && break
  [ "$TEST_FIRST" = true ] && [ $PART -eq 1 ] && break

  START=$(float_sub $END $OVERLAP)
  PART=$((PART + 1))

  float_lt $(float_sub $DURATION $START) $(float_add $OVERLAP 1) && break
done

# Process segments
TOTAL_SEGMENTS=${#VIDEO_SEGMENTS[@]}
CURRENT_SEGMENT=0
CREATED_FILES=()

for segment in "${VIDEO_SEGMENTS[@]}"; do
  IFS=':' read -r seg_start seg_end seg_part <<< "$segment"

  IS_LAST="false"
  [ $seg_part -eq $ESTIMATED_PARTS ] && IS_LAST="true"

  part_padded=$(printf "%0${PADDING_LENGTH}d" $seg_part)
  output_file="$OUTPUT_DIR/${FILENAME}_parte_${part_padded}.${EXTENSION}"

  # Determine correct path based on environment
  if [ "$RUNNING_IN_DOCKER" = true ]; then
    # Inside Docker: use direct path
    output_file_target="$output_file"
    input_file_target="/videos/$(basename "$INPUT_FILE")"
  else
    # Local: convert to Docker paths
    output_file_target="/videos/$FILENAME/${FILENAME}_parte_${part_padded}.${EXTENSION}"
    input_file_target="/videos/$(basename "$INPUT_FILE")"
  fi

  # Build filter
  filter=""
  if [ "$ADD_LABEL" = "on" ] || [ -n "$TITLE_TEXT" ] || [ "$CROP_TOP" -gt 0 ] || [ "$CROP_BOTTOM" -gt 0 ] || [ "$CROP_LEFT" -gt 0 ] || [ "$CROP_RIGHT" -gt 0 ]; then
    filter=$(build_ffmpeg_filter "$seg_part" "$ESTIMATED_PARTS" "$IS_LAST" "$VIDEO_ASPECT" "$TITLE_TEXT" "$OVERLAP" "$ADD_LABEL" "$CUSTOM_LABEL" "$CROP_TOP" "$CROP_BOTTOM" "$CROP_LEFT" "$CROP_RIGHT")
  fi

  # Process using appropriate ffmpeg command
  if process_video_segment "$seg_start" "$seg_end" "$seg_part" "$IS_LAST" "run_ffmpeg" "$filter" "$output_file_target" "$input_file_target" "$PADDING_LENGTH" "$ESTIMATED_PARTS" "$ADD_LABEL" "$TITLE_TEXT"; then
    CREATED_FILES+=("$(basename "$output_file")")
  fi

  CURRENT_SEGMENT=$((CURRENT_SEGMENT + 1))
  show_progress $CURRENT_SEGMENT $TOTAL_SEGMENTS
  echo ""
  echo ""
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
[ "$TEST_FIRST" = true ] && echo -e "${GREEN}║       ✓ TEST COMPLETE!                    ║${NC}" || echo -e "${GREEN}║            ✓ COMPLETE!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📊 Summary:${NC}"
echo -e "   • Original file: ${BLUE}$INPUT_FILE${NC}"
echo -e "   • Parts created: ${GREEN}${#CREATED_FILES[@]}${NC}"
[ "$ADD_LABEL" = "on" ] && echo -e "   • Label: ${GREEN}✓${NC}"
[ -n "$TITLE_TEXT" ] && echo -e "   • Title: ${GREEN}✓${NC} (${OVERLAP}s)"
echo -e "   • Output: ${BLUE}$OUTPUT_DIR${NC}"
echo ""
[ "$TEST_FIRST" = true ] && echo -e "${YELLOW}🧪 Check before processing all videos!${NC}" && echo ""
echo -e "${GREEN}📂 Created files:${NC}"
for file in "${CREATED_FILES[@]}"; do
  if [ -f "$OUTPUT_DIR/$file" ]; then
    size=$(ls -lh "$OUTPUT_DIR/$file" | awk '{print $5}')
    echo -e "   • $file ${YELLOW}($size)${NC}"
  fi
done
echo ""

# Cleanup temporary trimmed video
if [ "$CLEANUP_TEMP" = true ] && [ -f "$VIDEO_PATH" ]; then
  echo -e "${BLUE}🧹 Cleaning up temporary files...${NC}"
  rm -f "$VIDEO_PATH"
  echo -e "${GREEN}✓ Temporary trimmed video removed${NC}"
  echo ""
fi

