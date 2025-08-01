#!/opt/homebrew/bin/bash

# WARNING: This script will irreversibly delete all files and directories named "$1"
# in the current directory and subdirectories. Use with extreme caution.
#
# This script:
# 1. Deletes all files named "$1".
# 2. Deletes all directories named "$1".
#
# Example usage:
# $ ./remove_target.sh "old_file"

if [ -z "$1" ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

target="$1"

# Display warning and confirm action
echo "This script will delete all files and directories named '$target' in the current directory and subdirectories."
echo "Are you absolutely sure? (y/n)"
read answer

if [[ "$answer" != "y" ]]; then
    echo "Aborting."
    exit 1
fi

# Delete all matching files
echo "Deleting files named '$target'..."
find . -type f -name "$target" -exec rm -i -f {} \;

# Delete all matching directories
echo "Deleting directories named '$target'..."
find . -type d -name "$target" -exec rm -i -rf {} \;

echo "Operation completed."
