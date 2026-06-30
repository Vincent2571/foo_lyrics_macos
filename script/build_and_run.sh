#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/foobar2000/foo_lyrics_macos/foo_lyrics_macos.xcodeproj"
DERIVED="$ROOT_DIR/build/DerivedData"
PRODUCT="$DERIVED/Build/Products/Release/foo_lyrics_macos.component"
DIST="$ROOT_DIR/dist"

xcodebuild -quiet -project "$PROJECT" -scheme foo_lyrics_macos -configuration Release \
  -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO build
mkdir -p "$DIST"
ditto "$PRODUCT" "$DIST/foo_lyrics_macos.component"

case "$MODE" in
  run|--verify|verify)
    test -x "$DIST/foo_lyrics_macos.component/Contents/MacOS/foo_lyrics_macos"
    file "$DIST/foo_lyrics_macos.component/Contents/MacOS/foo_lyrics_macos"
    ;;
  --debug|debug|--logs|logs|--telemetry|telemetry)
    echo "This target is loaded inside foobar2000; install it and use View > Console for runtime diagnostics."
    ;;
  *)
    echo "usage: $0 [run|--verify|--debug|--logs|--telemetry]" >&2
    exit 2
    ;;
esac
