#!/bin/bash
# 尝试使用 macOS 默认应用程序路径启动 Godot 并打开当前项目
"/Applications/Godot.app/Contents/MacOS/Godot" -e --path "$(pwd)"
