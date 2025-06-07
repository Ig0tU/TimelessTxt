#!/bin/bash
set -e

echo "🧹 Cleaning previous publish output..."
rm -rf publish/*

if [ -z "$1" ]; then
  echo "❌ Usage: $0 <version>"
  echo "👉 Example: ./build-all.sh 1.2.3"
  exit 1
fi

version="$1"
app_name="MusicLyricApp"
project_path="./MusicLyricApp/MusicLyricApp.csproj"
output_root="publish"

targets=(
  "win-x64"
  "linux-x64"
  "osx-x64"
  "osx-arm64"
)

# macOS 图标文件路径（icns）
macos_icon_source="./MusicLyricApp/Resources/app-logo.icns"

trap 'echo "❌ An error occurred. Exiting."' ERR

mkdir -p "$output_root"

for target in "${targets[@]}"; do
  echo -e "\n-----------------------------"
  echo "📦 Publishing for $target..."

  output_dir="$output_root/$target"
  dotnet publish "$project_path" \
    -c Release \
    -r "$target" \
    --self-contained true \
    -p:DebugType=None \
    -p:PublishSingleFile=true \
    -p:IncludeNativeLibrariesForSelfExtract=true \
    -o "$output_dir"

  if [[ "$target" == win-* ]]; then
    ext=".exe"
    original_file=$(find "$output_dir" -type f -name "*$ext" -print -quit)
    if [[ -n "$original_file" ]]; then
      new_filename="${app_name}-${version}-${target}${ext}"
      mv "$original_file" "$output_dir/$new_filename"
      echo "✅ Renamed Windows executable to: $new_filename"
    fi
  fi

  # macOS 目标单独处理图标复制
  if [[ "$target" == osx-* ]]; then
    if [ ! -f "$macos_icon_source" ]; then
      echo "❌ macOS icon file not found at '$macos_icon_source'. Please check."
      exit 1
    fi
    mkdir -p "$output_dir/Resources"
    cp "$macos_icon_source" "$output_dir/Resources/"
    echo "🎨 Copied macOS icon to $output_dir/Resources/"
  fi

  # Determine archive name
  if [[ "$target" == osx-* ]]; then
    archive_name="${app_name}-${version}-${target}-mid.tar.gz"
  else
    archive_name="${app_name}-${version}-${target}.tar.gz"
  fi

  tar -czf "$output_root/$archive_name" -C "$output_dir" .
  echo "🗜️  Compressed to: $archive_name"

  echo "🧹 Removing intermediate directory: $output_dir"
  rm -rf "$output_dir"
done

echo -e "\n✅ All targets published and compressed."
echo "💡 To package macOS .app, copy the -mid tar.gz files to a macOS machine and run: ./build-macos-app.sh $version"
