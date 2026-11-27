#!/bin/bash
# Builds Countdown.saver as a universal (Apple Silicon + Intel) bundle.
# Needs only the Xcode Command Line Tools, not the full Xcode app.
#
#   ./build.sh            build into build/Countdown.saver
#   ./build.sh install    build, then install into ~/Library/Screen Savers
#   ./build.sh snapshot   build a tool that renders sample screenshots into build/snapshots
#   ./build.sh check      build, then run layout and timing checks (exits 1 on failure)

set -euo pipefail
cd "$(dirname "$0")"

BUILD=build
SAVER="$BUILD/Countdown.saver"
MIN_MACOS=13.0

rm -rf "$SAVER" "$BUILD/obj"
mkdir -p "$SAVER/Contents/MacOS" "$BUILD/obj"

for arch in arm64 x86_64; do
	echo "Compiling for $arch…"
	swiftc -swift-version 5 -O \
		-module-name Countdown \
		-target "$arch-apple-macos$MIN_MACOS" \
		-emit-executable -Xlinker -bundle \
		-framework ScreenSaver -framework AppKit \
		Sources/*.swift \
		-o "$BUILD/obj/Countdown-$arch"
done

lipo -create "$BUILD"/obj/Countdown-arm64 "$BUILD"/obj/Countdown-x86_64 -output "$SAVER/Contents/MacOS/Countdown"
cp Support/Info.plist "$SAVER/Contents/Info.plist"
codesign --force --sign - "$SAVER"
rm -rf "$BUILD/obj"
echo "Built $SAVER"

case "${1:-}" in
install)
	DEST="$HOME/Library/Screen Savers/Countdown.saver"
	rm -rf "$DEST"
	cp -R "$SAVER" "$DEST"
	# Make System Settings and the screen saver host load the new version.
	killall legacyScreenSaver legacyScreenSaver-x86_64 2>/dev/null || true
	echo "Installed to $DEST"
	;;
snapshot)
	swiftc -swift-version 5 -module-name Countdown -framework ScreenSaver -framework AppKit \
		Sources/*.swift Tools/main.swift -o "$BUILD/snapshot"
	mkdir -p "$BUILD/snapshots"
	"$BUILD/snapshot" "$BUILD/snapshots"
	;;
check)
	swiftc -swift-version 5 -module-name Countdown -framework ScreenSaver -framework AppKit \
		Sources/*.swift Tools/Check/main.swift -o "$BUILD/check"
	"$BUILD/check"
	;;
esac
