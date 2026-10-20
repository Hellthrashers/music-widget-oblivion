#!/bin/sh
set -eu

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
APP_DIR="$ROOT_DIR/.build/MusicWidget.app"
CONTENTS_DIR="$APP_DIR/Contents"

cd "$ROOT_DIR"
swift build --configuration release

mkdir -p "$CONTENTS_DIR/MacOS"
cp "$ROOT_DIR/.build/release/MusicWidget" "$CONTENTS_DIR/MacOS/MusicWidget"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

printf 'Created %s\n' "$APP_DIR"
