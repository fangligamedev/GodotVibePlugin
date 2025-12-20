#!/bin/bash

# Check if a path argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <path_to_project>"
  echo "Example: $0 ~/Documents/MyNewGame"
  exit 1
fi

PROJECT_PATH="$1"

# Check if the directory exists
if [ ! -d "$PROJECT_PATH" ]; then
  echo "Error: Directory '$PROJECT_PATH' does not exist."
  exit 1
fi

echo "Opening Godot project at: $PROJECT_PATH"
"/Applications/Godot.app/Contents/MacOS/Godot" -e --path "$PROJECT_PATH"
