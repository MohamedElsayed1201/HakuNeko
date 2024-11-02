#!/bin/bash

#set -x # Enable debug mode for tracing commands
#set -e  # Exit immediately if a command exits with a non-zero status

# Ensure required commands are installed
command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg is required but not installed,try 'sudo apt install -y ffmpeg'. Aborting."; exit 1; }

# Constants
USERNAME="$(whoami)"                         # Get the current username
BACKUP_DIR="/home/$USERNAME/backups"         # Base backup directory
LOG_DIR="$BACKUP_DIR/log"                    # Base Log directory
OUTPUT_DIR="$(pwd)"                          # Output directory for .mkv files
OUTPUT_EXT="mkv"                             # Output file extension
LOGFILE="$LOG_DIR/hakuneko.log"              # Main script log file
FFMPEG_LOG="$LOG_DIR/hakuneko_ffmpeg.log"    # FFmpeg error log file

# Check and create backup and log directories if they do not exist
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Check if the output directory is writable
if [ ! -w "$OUTPUT_DIR" ]; then
    echo "Output directory is not writable: $OUTPUT_DIR"
    exit 1
fi

# Create log file
exec > >(tee -a "$LOGFILE") 2>&1
echo "[$(date +'%m-%d-%Y %H:%M:%S')] Starting video and audio extraction..."

# Function to process a directory
process_directory() {
    local dir="$1"
    local dirname
    local dirnumber

    # Extract directory name
    dirname=$(basename "$dir")

    # Extract only the numeric part of the directory name
    dirnumber="${dirname%.*}"

    # Check if the directory exists
    if [ ! -d "$dir" ]; then
    # if tests is the file not exists and is a directory
        echo "Directory does not exist: $dir"
        return 1
    fi

    # Define output path
    local output_path="${OUTPUT_DIR}/${dirnumber}.${OUTPUT_EXT}"

    # Check if the output file already exists and has content
    if [ -e "$output_path" ] && [ "$(stat -c '%s' "$output_path")" -gt 0 ]; then
    # if tests is the file exists and is gt 0
        echo "File already exists: $output_path"
        return 0
    fi

    # Run ffmpeg to extract video and audio streams
    echo "Extracting video and audio streams in folder $dirnumber"
    if ! ffmpeg -loglevel error -allowed_extensions ALL -protocol_whitelist concat,file,http,https,tcp,tls,crypto \
    -i "$dir/media.m3u8" -map 0:v -map 0:a -c copy -f matroska -y "$output_path" >> "$FFMPEG_LOG" 2>&1; then
        echo "ffmpeg failed. Check ${FFMPEG_LOG} for details."
        return 1
    fi
    echo "Extraction successful for $output_path"
    return 0
}

# Get the list of directories containing '.m3u8' files
directories=() # Initialize an empty array
while IFS= read -r -d '' dir; do
    # Only include directories with .m3u8 files inside
    if ls "$dir"/*.m3u8 >/dev/null 2>&1; then
        directories+=("$dir") # Append to array
    fi
done < <(find . -maxdepth 1 -type d ! -name . -print0 | sort -zV)

# Iterate over each directory
for dir in "${directories[@]}"; do
    if [[ "$dir" == "." ]]; then
        continue
    fi
    echo "Processing directory: $dir"
    process_directory "$dir"
done

# Confirmation for deleting directories after extraction
read -r -p "Do you want to remove the processed directories? [y/n, default: y]: " confirm
confirm="${confirm:-y}"
if [[ "${confirm,,}" == "y" ]]; then
    for dir in "${directories[@]}"; do
        dirname=$(basename "$dir")
        echo "Removing directory: $dirname"
        rm -rf "$dirname"
    done
    echo "All processed directories have been removed."
else
    echo "Directories were not removed."
fi

# Cleanup function to remove the temporary files
cleanup() {
    rm -f "$LOGFILE" "$FFMPEG_LOG"
}
trap cleanup EXIT

