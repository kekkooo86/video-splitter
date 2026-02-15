#!/bin/bash

# Video Splitter - Local Version
# Wrapper that loads core functions and uses Docker for ffmpeg

set -e

# Load shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/split_video_core.sh"

# Configuration specific to local use (with Docker)
VIDEO_DIR="."
FFMPEG_CMD_TEMPLATE="docker run --rm -v VIDEO_DIR_PLACEHOLDER:/videos jrottenberg/ffmpeg"

# Helper to build ffmpeg command with correct paths
build_ffmpeg_cmd() {
  echo "$FFMPEG_CMD_TEMPLATE" | sed "s|VIDEO_DIR_PLACEHOLDER|$VIDEO_DIR|g"
}

# Wrapper to call ffmpeg with correct paths
run_ffmpeg() {
  local video_dir_abs=$(cd "$VIDEO_DIR" && pwd)
  docker run --rm -v "$video_dir_abs:/videos" \
    -e FONTCONFIG_FILE=/dev/null \
    jrottenberg/ffmpeg "$@"
}

# Default values
SEGMENT_DURATION=60
OVERLAP=5
INPUT_FILE=""
INTERACTIVE=false
ADD_LABEL="on"
TITLE_TEXT=""
MAX_PARALLEL=1
TEST_FIRST=false

# If no arguments, use interactive mode
if [ $# -eq 0 ]; then
  INTERACTIVE=true
fi

# Parse arguments
while getopts "i:d:s:o:l:T:p:h-:" opt; do
  case $opt in
    i) INPUT_FILE="$OPTARG" ;;
    d) VIDEO_DIR="$OPTARG" ;;
    s) SEGMENT_DURATION="$OPTARG" ;;
    o) OVERLAP="$OPTARG" ;;
    l) ADD_LABEL="$OPTARG" ;;
    T) TITLE_TEXT="$OPTARG" ;;
    p) MAX_PARALLEL="$OPTARG" ;;
    h)
      echo "Usage: $0 [options]"
      echo ""
      echo "Without options: interactive mode"
      echo ""
      echo "Options:"
      echo "  -i  Video file name"
      echo "  -d  Directory containing the video (default: .)"
      echo "  -s  Duration of each segment in seconds (default: 60)"
      echo "  -o  Overlap between segments in seconds (default: 5)"
      echo "  -l  Add permanent 'Part X' label (on/off, default: on)"
      echo "  -T  Intro title (use | for line break)"
      echo "  -p  Number of parallel processes (default: 1, max: 3)"
      echo "  --test-first  Test only the first video"
      echo "  -h  Show this help"
      echo ""
      echo "Examples:"
      echo "  $0 -i documentary.mp4 -s 60 -o 5 -T \"Documentary South 1992\""
      echo "  $0 -i video.mp4 -T \"Series PIPE Episode 1\" -p 2"
      exit 0
      ;;
    -)
      case "${OPTARG}" in
        test-first) TEST_FIRST=true ;;
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
[ "$ADD_LABEL" = "on" ] && echo -e "${GREEN}🏷️  Permanent label:${NC} Enabled"
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

ESTIMATED_PARTS=$(((DURATION - OVERLAP) / (SEGMENT_DURATION - OVERLAP) + 1))
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

while [ $START -lt $DURATION ]; do
  END=$((START + SEGMENT_DURATION))
  [ $END -gt $DURATION ] && END=$DURATION

  NEXT_START=$((END - OVERLAP))
  REMAINING=$((DURATION - NEXT_START))

  if [ $REMAINING -gt 0 ] && [ $REMAINING -lt $((SEGMENT_DURATION / 2)) ]; then
    if [ "$INTERACTIVE" = true ]; then
      handle_short_final_segment $REMAINING $SEGMENT_DURATION && SKIP_LAST=false || SKIP_LAST=true
      [ "$SKIP_LAST" = true ] && END=$DURATION
    fi
  fi

  VIDEO_SEGMENTS+=("$START:$END:$PART")

  [ "$SKIP_LAST" = true ] && break
  [ "$TEST_FIRST" = true ] && [ $PART -eq 1 ] && break

  START=$((END - OVERLAP))
  PART=$((PART + 1))

  [ $((DURATION - START)) -lt $((OVERLAP + 1)) ] && break
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

  # Build filter
  filter=""
  if [ "$ADD_LABEL" = "on" ] || [ -n "$TITLE_TEXT" ]; then
    filter=$(build_ffmpeg_filter "$seg_part" "$ESTIMATED_PARTS" "$IS_LAST" "$VIDEO_ASPECT" "$TITLE_TEXT" "$OVERLAP" "$ADD_LABEL")
  fi

  # Process using Docker
  if process_video_segment "$seg_start" "$seg_end" "$seg_part" "$IS_LAST" "run_ffmpeg" "$filter" "$output_file" "/videos/$(basename "$INPUT_FILE")" "$PADDING_LENGTH" "$ESTIMATED_PARTS" "$ADD_LABEL" "$TITLE_TEXT"; then
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

