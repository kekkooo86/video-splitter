#!/bin/bash

# Core functions for video splitting
# This file contains ONLY shared functions, no execution logic

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display progress bar
show_progress() {
  local current=$1
  local total=$2
  local width=50
  local percentage=$((current * 100 / total))
  local filled=$((width * current / total))

  printf "\r${BLUE}Progress: [${NC}"
  printf "%${filled}s" | tr ' ' '█'
  printf "%$((width - filled))s" | tr ' ' '░'
  printf "${BLUE}] ${percentage}%% (${current}/${total})${NC}"
}

# Function to detect video aspect ratio
# Parameters: $1=video_path, $2=ffmpeg_command
detect_aspect_ratio() {
  local video_path=$1
  local ffmpeg_cmd=$2

  echo -e "${YELLOW}⏳ Detecting video aspect ratio...${NC}" >&2

  # Get video dimensions using passed ffmpeg command
  local dimensions=$($ffmpeg_cmd -i "$video_path" 2>&1 | grep "Stream.*Video" | sed -n 's/.*, \([0-9]*x[0-9]*\).*/\1/p' | head -1)

  if [ -z "$dimensions" ]; then
    echo "vertical"  # Default fallback
    return
  fi

  local width=$(echo $dimensions | cut -d'x' -f1)
  local height=$(echo $dimensions | cut -d'x' -f2)

  # Calculate ratio
  local ratio=$(echo "scale=2; $width/$height" | bc)

  echo -e "${GREEN}✓ Dimensions: ${width}x${height} (ratio: $ratio)${NC}" >&2

  # Determine type
  if (( $(echo "$ratio > 1.5" | bc -l) )); then
    echo "horizontal"  # 16:9
  elif (( $(echo "$ratio < 0.7" | bc -l) )); then
    echo "vertical"    # 9:16
  else
    echo "square"      # 1:1
  fi
}

# Function to get font sizes based on aspect ratio
get_font_sizes() {
  local aspect=$1

  case $aspect in
    vertical)
      echo "28:40"  # label:title
      ;;
    horizontal)
      echo "36:60"
      ;;
    square)
      echo "32:52"
      ;;
    *)
      echo "36:60"  # default
      ;;
  esac
}

# Function to find font path
find_font_path() {
  local font_type=$1  # "regular" or "bold"

  if [ "$font_type" = "bold" ]; then
    # Try bold fonts in order
    [ -f "/usr/share/fonts/ttf-liberation/LiberationSans-Bold.ttf" ] && echo "/usr/share/fonts/ttf-liberation/LiberationSans-Bold.ttf" && return
    [ -f "/usr/share/fonts/ttf-dejavu/DejaVuSans-Bold.ttf" ] && echo "/usr/share/fonts/ttf-dejavu/DejaVuSans-Bold.ttf" && return
    [ -f "/System/Library/Fonts/Supplemental/Arial Bold.ttf" ] && echo "/System/Library/Fonts/Supplemental/Arial Bold.ttf" && return
    # Fallback
    echo "/usr/share/fonts/ttf-liberation/LiberationSans-Bold.ttf"
  else
    # Try regular fonts in order
    [ -f "/usr/share/fonts/ttf-liberation/LiberationSans-Regular.ttf" ] && echo "/usr/share/fonts/ttf-liberation/LiberationSans-Regular.ttf" && return
    [ -f "/usr/share/fonts/ttf-dejavu/DejaVuSans.ttf" ] && echo "/usr/share/fonts/ttf-dejavu/DejaVuSans.ttf" && return
    [ -f "/System/Library/Fonts/Supplemental/Arial.ttf" ] && echo "/System/Library/Fonts/Supplemental/Arial.ttf" && return
    [ -f "/System/Library/Fonts/Helvetica.ttc" ] && echo "/System/Library/Fonts/Helvetica.ttc" && return
    # Fallback
    echo "/usr/share/fonts/ttf-liberation/LiberationSans-Regular.ttf"
  fi
}

# Function to process title with custom separator
process_title_text() {
  local text="$1"

  if [ -z "$text" ]; then
    echo ""
    return
  fi

  # Replace | character with newline
  echo "$text" | sed 's/|/\n/g'
}

# Function to build ffmpeg filter
build_ffmpeg_filter() {
  local part=$1
  local total=$2
  local is_last=$3
  local aspect=$4
  local title_text=$5
  local overlap_duration=$6
  local add_label=$7

  local filter=""
  local font_regular=$(find_font_path "regular")
  local font_bold=$(find_font_path "bold")
  local sizes=$(get_font_sizes "$aspect")
  local label_size=$(echo $sizes | cut -d':' -f1)
  local title_size=$(echo $sizes | cut -d':' -f2)

  # Calculate padding for box
  local label_padding=$((label_size / 4))
  local title_padding=$((title_size / 3))

  # Permanent label
  if [ "$add_label" = "on" ]; then
    if [ "$is_last" = "true" ]; then
      filter="drawtext=text='Final Part':fontfile=${font_regular}:fontsize=${label_size}:fontcolor=white:box=1:boxcolor=black@0.8:boxborderw=${label_padding}:x=w-tw-15:y=15"
    else
      filter="drawtext=text='Part ${part}':fontfile=${font_regular}:fontsize=${label_size}:fontcolor=white:box=1:boxcolor=black@0.8:boxborderw=${label_padding}:x=w-tw-15:y=15"
    fi
  fi

  # Centered intro title
  if [ -n "$title_text" ]; then
    local processed_title=$(process_title_text "$title_text")
    local escaped_title=$(echo -e "$processed_title" | sed "s/'/\\\\\'/g" | sed 's/:/\\:/g' | sed 's/\n/\\n/g')

    local fade_out=0.5
    local fade_start=$(echo "$overlap_duration - $fade_out" | bc)

    local title_filter="drawtext=text='${escaped_title}':fontfile=${font_bold}:fontsize=${title_size}:fontcolor=white:box=1:boxcolor=black@0.8:boxborderw=${title_padding}:x=(w-tw)/2:y=(h-th)/2:line_spacing=8:enable='between(t,0,${overlap_duration})':alpha='if(gte(t,${fade_start}),1-((t-${fade_start})/${fade_out}),1)'"

    if [ -n "$filter" ]; then
      filter="${filter},${title_filter}"
    else
      filter="${title_filter}"
    fi
  fi

  echo "$filter"
}

# Function to convert seconds to HH:MM:SS format
format_time() {
  local total_seconds=$1
  local hours=$((total_seconds / 3600))
  local minutes=$(((total_seconds % 3600) / 60))
  local seconds=$((total_seconds % 60))
  printf "%02d:%02d:%02d" $hours $minutes $seconds
}

# Function to get video duration
# Parameters: $1=video_path, $2=ffmpeg_command
get_video_duration() {
  local video_path=$1
  local ffmpeg_cmd=$2

  local duration=$($ffmpeg_cmd -i "$video_path" 2>&1 | \
    grep "Duration" | \
    awk '{print $2}' | \
    tr -d , | \
    awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')

  if [ -z "$duration" ]; then
    echo ""
    return 1
  fi

  # Remove decimals
  echo "${duration%.*}"
  return 0
}

# Function to ask what to do with short final segment
handle_short_final_segment() {
  local remaining=$1
  local segment_duration=$2
  local threshold=$((segment_duration / 2))

  if [ $remaining -lt $threshold ]; then
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: Last segment would be only $remaining seconds${NC}"
    echo -e "${YELLOW}   (less than half of required duration: $segment_duration seconds)${NC}"
    echo ""
    echo -e "${BLUE}What do you want to do?${NC}"
    echo -e "  ${GREEN}1.${NC} Create last segment separately (even if short)"
    echo -e "  ${GREEN}2.${NC} Merge with previous segment (will be longer)"
    echo ""
    read -p "Choose (1 or 2): " choice
    echo ""

    if [ "$choice" = "2" ]; then
      return 1  # Signal to merge
    else
      return 0  # Create separately
    fi
  fi

  return 0
}

# Function to process single video segment
# Parameters: $1=start, $2=end, $3=part, $4=is_last, $5=ffmpeg_cmd, $6=filter, $7=output_file, $8=input_file
process_video_segment() {
  local start=$1
  local end=$2
  local part=$3
  local is_last=$4
  local ffmpeg_cmd=$5
  local filter=$6
  local output_file=$7
  local input_file=$8
  local padding_length=$9
  local estimated_parts=${10}
  local add_label=${11}
  local title_text=${12}

  local start_time=$(format_time $start)
  local end_time=$(format_time $end)
  local part_padded=$(printf "%0${padding_length}d" $part)
  local duration=$((end - start))

  echo -e "${YELLOW}🎬 Part $part_padded/$estimated_parts${NC}: $start_time → $end_time"

  # Determine if using labels/titles
  if [ "$add_label" = "on" ] || [ -n "$title_text" ]; then
    if [ -n "$filter" ]; then
      echo -e "${BLUE}   ⚙️  Encoding with labels...${NC}"
      $ffmpeg_cmd \
        -ss "$start_time" \
        -i "$input_file" \
        -t "$duration" \
        -vf "$filter" \
        -c:v libx264 -crf 23 -preset medium \
        -c:a aac -b:a 128k \
        -pix_fmt yuv420p \
        "$output_file" \
        -loglevel error -stats -y 2>&1 | grep -Ev "(frame=|Fontconfig)" || true
    else
      $ffmpeg_cmd \
        -ss "$start_time" \
        -i "$input_file" \
        -t "$duration" \
        -c copy \
        "$output_file" \
        -loglevel error -stats -y 2>&1 | grep -Ev "(frame=|Fontconfig)" || true
    fi
  else
    # Fast copy without re-encoding
    $ffmpeg_cmd \
      -ss "$start_time" \
      -i "$input_file" \
      -t "$duration" \
      -c copy \
      "$output_file" \
      -loglevel error -stats -y 2>&1 | grep -Ev "(frame=|Fontconfig)" || true
  fi

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✓ Created: $(basename "$output_file")${NC}"
    return 0
  else
    echo -e "${RED}   ✗ Error creating file${NC}"
    return 1
  fi
}

