#!/bin/bash

#set -x # Enable debug mode for tracing commands
#set -v # Enable verbose mode for tracing commands
#set -e # Exit immediately if a command exits with a non-zero status

# Ensure required command are installed
command -v ffmpeg >/dev/null 2>&1 || {
    echo "Command ffmpeg not found, but can be installed with:"
    echo "sudo apt install ffmpeg"
    echo "Please ask your administrator"
    echo "Exiting..."
    exit 1
}

## Ensure required commands are installed
#for cmd in ffmpeg parallel; do
#    command -v "$cmd" >/dev/null 2>&1 || {
#    echo "Command '$cmd' not found, but can be installed with:"
#    echo "apt install $cmd"
#    echo "Please ask your administrator"
#    echo "Exiting..."
#    exit 1
#    }
#done

# Constants
LOG_DIR="$HOME/local/log"           # Base Log directory
OUTPUT_DIR="$(pwd)"                 # Output directory for *.mkv files
OUTPUT_EXT="mkv"                    # Output file extension
LOG_FILE="$LOG_DIR/hakuneko.log"    # Main script log file
FFMPEG_LOG="$LOG_DIR/ffmpeg.log"    # FFmpeg error log file

# function to Ensure required directories are writable and check if they are exists
writable_exist() {
    local dir="$1"
    if [ ! -w "$dir" ]; then
        echo "No write permission to the directory $dir Aborting..."
        exit 1
    fi
    if [ ! -d "$dir" ]; then
        echo "Directory does not exist: $dir"
        mkdir -p "$dir"
        echo "Created directory: $dir"
    fi
}

writable_exist "$LOG_DIR"
writable_exist "$OUTPUT_DIR"

# Create log file
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[$(date +'%m-%d-%Y %H:%M:%S')] Starting video and audio extraction..."

# Function to process the directories
process_directory() {
    local dir="$1"
    local dirname
    local dirnumber
    local output_path

    dirname=$(basename "$dir")
    dirnumber="${dirname%.*}"
    output_path="${OUTPUT_DIR}/${dirnumber}.${OUTPUT_EXT}"

    # Check if the output file already exists and has content
    if [ -e "$output_path" ] && [ "$(stat -c '%s' "$output_path")" -gt 0 ]; then
        echo "File already exists: ${dirnumber}.${OUTPUT_EXT}"
        return 0
    fi

    # Run ffmpeg to extract video and audio streams
    echo "Extracting video and audio streams in folder $dirnumber"
    if ! ffmpeg -loglevel error -allowed_extensions ALL -protocol_whitelist concat,file,http,https,tcp,tls,crypto \
    -i "$dir/media.m3u8" -map 0:v -map 0:a -c copy -f matroska -y "$output_path" >> "$FFMPEG_LOG" 2>&1; then
        echo "ffmpeg failed. Check ${FFMPEG_LOG} for details."
        return 1
    fi
    echo "Extraction successful for $dirnumber"
    return 0
}

# Get the list of directories containing '.m3u8' files
directories=()
while IFS= read -r -d '' dir; do
    # Only include directories with .m3u8 files inside
    if ls "$dir"/*.m3u8 >/dev/null 2>&1; then
        directories+=("$dir")
    fi
done < <(find . -maxdepth 1 -type d ! -name . -print0 | sort -zV)

# Iterate over each directory using for loop
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
    rm -f "$LOG_FILE" "$FFMPEG_LOG"
}
trap cleanup EXIT

exit 0
