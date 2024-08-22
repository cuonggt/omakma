#!/bin/bash

# Function to check if running on macOS 14.5 or higher
check_macos_version() {
  VERSION_ID=${1:-$(sw_vers -productVersion)}

  if awk -v ver="$VERSION_ID" 'BEGIN {exit !(ver >= 14.5)}'; then
    return 0
  else
    echo "Error: macOS version must be 14.5 or higher. Current version: $VERSION_ID" >&2
    return 1
  fi
}

if ! check_macos_version; then
  echo "Script execution failed due to system requirements not being met." >&2
  exit 1
fi
