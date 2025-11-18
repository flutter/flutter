#!/bin/bash

SRC_DIR="."
DEST_DIR="out_js"

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Loop through all .dart files in the source directory
for DART_FILE in "$SRC_DIR"/*.dart; do
    # Extract the filename without the extension
    BASENAME=$(basename "$DART_FILE" .dart)
    # Define the output JavaScript file path
    JS_OUTPUT="$DEST_DIR/$BASENAME.js"

    echo "Compiling $DART_FILE to $JS_OUTPUT..."
    # Run the compilation command
    dart compile js -o "$JS_OUTPUT" "$DART_FILE"
done

echo "Batch conversion complete."
