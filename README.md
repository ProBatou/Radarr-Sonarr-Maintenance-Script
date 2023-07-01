# Radarr-Sonarr Maintenance Script

This repository contains a shell script called "Radarr-Sonarr Maintenance Script" to perform maintenance tasks on a storage system using Radarr and Sonarr.

## Prerequisites

Before running this script, make sure you have the following:

- An operating system compatible with Bash.
- The `curl` and `jq` packages installed.

## Configuration

Before running the script, you need to configure the following variables in the file:

- `CAPACITY`: The maximum capacity (in percentage) of the file system for storage.
- `FILESYSTEM`: The path of the file system for storage.
- `RADARR`: The URL of the Radarr web interface.
- `RADARR_KEY`: The API key to access Radarr.
- `SONARR`: The URL of the Sonarr API.
- `SONARR_KEY`: The API key to access Sonarr.

## Usage

1. Make sure you have configured the configuration variables correctly.
2. Open a terminal.
3. Navigate to the directory containing the script.
4. Run the following command:
   ```
   ./radarr-sonarr-maintenance-script.sh
   ```

The "Radarr-Sonarr Maintenance Script" will perform the following tasks:

1. Check the capacity of the file system.
2. Remove completed series (older than 180 days) from the specified paths in Sonarr.
3. Remove movie directories (older than 90 days) from the specified directory.
4. Remove unmonitored series from Sonarr.
5. Remove unmonitored movies from Radarr.

Please note that this script performs file and directory deletion operations, so it is recommended to test it in a testing environment before using it on real data.

## Disclaimer

The use of the "Radarr-Sonarr Maintenance Script" is at your own risk. Make sure to back up your important data before running this script. The author will not be held responsible for any data loss or damages resulting from the use of this script.
