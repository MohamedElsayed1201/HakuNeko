# Backup and Extraction Script

A Bash script designed to automate the extraction of video and audio streams from `.m3u8` files found in multiple directories. The script utilizes `ffmpeg` for processing and handles directory and logging setups, providing options to clean up processed directories and temporary files after completion.

## Requirements

- **OS**: Linux (or compatible environment with `bash`)
- **Required Tool**: `ffmpeg` must be installed on the system.
  - To install `ffmpeg` on Ubuntu or Debian-based systems, run:
    ```bash
    sudo apt install -y ffmpeg
    ```

## Features

- **Backup & Logging**: Creates directories for backups and logs under the user's home directory.
- **Output Handling**: Stores extracted video files in `.mkv` format in the current working directory.
- **Cleanup Option**: Allows optional deletion of directories once processing is complete.

## Installation

1. Clone the repository or download the script.
2. Ensure the script has execution permissions:
   ```bash
   chmod +x scriptname.sh

Usage

Run the script from the directory containing the subdirectories with .m3u8 files:

./scriptname.sh

Script Parameters

The script doesn’t take any command-line arguments. Instead, it uses the following default settings:

    Backup Directory: /home/$USERNAME/backups
    Log Directory: /home/$USERNAME/backups/log
    Output Directory: The directory from which the script is executed
    Output Extension: .mkv

Optional Actions

After extracting media files, the script prompts the user to confirm the deletion of processed directories:

    Type y (default) to delete directories, or n to keep them.

Script Workflow

    Pre-run Checks:
        Verifies ffmpeg is installed.
        Ensures required backup and log directories exist.
        Confirms that the output directory is writable.

    Directory Processing:
        Identifies all directories in the current path containing .m3u8 files.
        For each directory:
            Extracts video and audio streams from the .m3u8 playlist using ffmpeg.
            Logs success or failure of each extraction to the main log file and an ffmpeg error log.

    Cleanup:
        Optionally removes processed directories and cleans up temporary log files.

Logging

Logs are stored in the log directory ($LOG_DIR):

    hakuneko.log: Main script log, containing general operation messages.
    hakuneko_ffmpeg.log: Contains ffmpeg-specific error messages for troubleshooting.

Error Handling

If ffmpeg fails to process a file, the error details will be saved in hakuneko_ffmpeg.log.
Example Output
Processing directory: ./example_dir
Extracting video and audio streams in folder example_dir
Extraction successful for ./example_dir/output.mkv
Do you want to remove the processed directories? [y/n, default: y]: y
Removing directory: example_dir
All processed directories have been removed.
License

This project is licensed under the MIT License.
---
Let me know if you'd like any adjustments!
