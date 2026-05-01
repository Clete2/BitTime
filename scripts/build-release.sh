#!/usr/bin/env bash
#
# Build BitTime.app and produce dist/BitTime-<version>.zip and
# dist/BitTime-<version>.dmg (drag-to-Applications installer).
#
# Usage:  scripts/build-release.sh <version>
#
# Invoked by semantic-release via @semantic-release/exec.
#
set -euo pipefail

VERSION="${1:?usage: build-release.sh <version>}"
SCHEME="BitTime"
CONFIGURATION="Release"
BUILD_DIR="build"
PRODUCTS_DIR="${BUILD_DIR}/Build/Products/${CONFIGURATION}"
DIST_DIR="dist"
ZIP_PATH="${DIST_DIR}/BitTime-${VERSION}.zip"
DMG_PATH="${DIST_DIR}/BitTime-${VERSION}.dmg"
DMG_VOLNAME="BitTime ${VERSION}"

echo "==> Cleaning"
rm -rf "${BUILD_DIR}" "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

echo "==> Generating Xcode project"
xcodegen generate

echo "==> Building (${CONFIGURATION}, universal x86_64+arm64, ad-hoc signed) version ${VERSION}"
xcodebuild \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "${BUILD_DIR}" \
  ARCHS="x86_64 arm64" \
  ONLY_ACTIVE_ARCH=NO \
  MARKETING_VERSION="${VERSION}" \
  CURRENT_PROJECT_VERSION="${GITHUB_RUN_NUMBER:-1}" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" \
  build

APP_PATH="${PRODUCTS_DIR}/BitTime.app"
if [[ ! -d "${APP_PATH}" ]]; then
  echo "error: ${APP_PATH} not found after build"
  exit 1
fi

echo "==> Verifying universal binaries"
for bin in \
  "${APP_PATH}/Contents/MacOS/BitTime" \
  "${APP_PATH}/Contents/Frameworks/BitTimeCore.framework/Versions/A/BitTimeCore" \
  "${APP_PATH}/Contents/PlugIns/BitTimeWidget.appex/Contents/MacOS/BitTimeWidget"; do
  if [[ ! -f "${bin}" ]]; then
    echo "error: expected binary not found: ${bin}"
    exit 1
  fi
  archs=$(lipo -archs "${bin}")
  echo "  ${bin}: ${archs}"
  if ! grep -q "x86_64" <<<"${archs}" || ! grep -q "arm64" <<<"${archs}"; then
    echo "error: ${bin} is not universal (got: ${archs})"
    exit 1
  fi
done

echo "==> Re-signing nested bundles ad-hoc with proper identifiers"
# Sign innermost first: framework, then extension, then app.
codesign --force --sign - --identifier app.bittime.BitTime.core \
  "${APP_PATH}/Contents/Frameworks/BitTimeCore.framework"
codesign --force --sign - --identifier app.bittime.BitTime.BitTimeWidget \
  --entitlements BitTimeWidget/BitTimeWidget.entitlements \
  "${APP_PATH}/Contents/PlugIns/BitTimeWidget.appex"
codesign --force --sign - --identifier app.bittime.BitTime \
  --entitlements BitTime/BitTime.entitlements \
  "${APP_PATH}"

echo "==> Verifying signature"
codesign --verify --verbose=2 "${APP_PATH}"
codesign -dv --verbose=2 "${APP_PATH}" 2>&1 | grep -E "Identifier|Signature|TeamIdentifier"

echo "==> Zipping"
ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${ZIP_PATH}"

echo "==> Computing SHA-256 (zip)"
shasum -a 256 "${ZIP_PATH}" | tee "${ZIP_PATH}.sha256"

echo "==> Building drag-to-Applications DMG"
rm -f "${DMG_PATH}"

# Generate the background image (arrow + "Drag to install" caption).
BG_PNG="${BUILD_DIR}/dmg-background.png"
swift scripts/make-dmg-background.swift "${BG_PNG}"

# Generate a .icns for the DMG volume icon from the app's source PNG.
VOL_ICONSET="${BUILD_DIR}/VolumeIcon.iconset"
VOL_ICNS="${BUILD_DIR}/VolumeIcon.icns"
ICON_SRC_PNG="BitTime.icon/Assets/icon_1280_bigdigits.png"
rm -rf "${VOL_ICONSET}" "${VOL_ICNS}"
mkdir -p "${VOL_ICONSET}"
for spec in \
  "16:icon_16x16.png" \
  "32:icon_16x16@2x.png" \
  "32:icon_32x32.png" \
  "64:icon_32x32@2x.png" \
  "128:icon_128x128.png" \
  "256:icon_128x128@2x.png" \
  "256:icon_256x256.png" \
  "512:icon_256x256@2x.png" \
  "512:icon_512x512.png" \
  "1024:icon_512x512@2x.png"; do
  size="${spec%%:*}"
  name="${spec##*:}"
  sips -z "${size}" "${size}" "${ICON_SRC_PNG}" --out "${VOL_ICONSET}/${name}" >/dev/null
done
iconutil -c icns "${VOL_ICONSET}" -o "${VOL_ICNS}"

DMG_STAGE_DIR="${BUILD_DIR}/dmg-stage"
rm -rf "${DMG_STAGE_DIR}"
mkdir -p "${DMG_STAGE_DIR}/.background"
ditto "${APP_PATH}" "${DMG_STAGE_DIR}/BitTime.app"
ln -s /Applications "${DMG_STAGE_DIR}/Applications"
cp "${BG_PNG}" "${DMG_STAGE_DIR}/.background/background.png"
cp "${VOL_ICNS}" "${DMG_STAGE_DIR}/.VolumeIcon.icns"

RAW_DMG="${BUILD_DIR}/BitTime-${VERSION}.raw.dmg"
rm -f "${RAW_DMG}"

# Create a writable DMG large enough to hold the staged contents.
hdiutil create \
  -srcfolder "${DMG_STAGE_DIR}" \
  -volname "${DMG_VOLNAME}" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -format UDRW \
  -ov \
  "${RAW_DMG}"

# Detach any stale mounts of a previous run to avoid the volume being
# remounted as "<name> 1", which would break the AppleScript below.
for stale in /Volumes/BitTime\ ${VERSION}*; do
  [[ -d "${stale}" ]] || continue
  echo "  detaching stale mount: ${stale}"
  hdiutil detach "${stale}" -quiet 2>/dev/null \
    || hdiutil detach "${stale}" -force 2>/dev/null \
    || true
done

# Mount at the default /Volumes/<volname> so Finder reliably registers the disk.
ATTACH_OUTPUT=$(hdiutil attach -readwrite -noverify "${RAW_DMG}")
echo "${ATTACH_OUTPUT}"
DEVICE=$(echo "${ATTACH_OUTPUT}" | grep -E '^/dev/' | tail -n1 | awk '{print $1}')
# Read the actual mount point hdiutil chose (may differ from DMG_VOLNAME if a
# stale mount with the same name still exists).
MOUNT_POINT=$(echo "${ATTACH_OUTPUT}" | grep -E '^/dev/' | tail -n1 | awk '{for(i=3;i<=NF;i++) printf "%s%s", $i, (i==NF?"":" ")}')
ACTUAL_VOLNAME=$(basename "${MOUNT_POINT}")
echo "  device:     ${DEVICE}"
echo "  mountpoint: ${MOUNT_POINT}"
echo "  volname:    ${ACTUAL_VOLNAME}"

# Mark the volume as having a custom icon (kHasCustomIcon flag). SetFile
# lives in the Xcode command-line tools; resolve it explicitly so we don't
# silently fall back to a no-op if it isn't on PATH.
SETFILE_BIN="$(xcrun --find SetFile 2>/dev/null || command -v SetFile || true)"
if [[ -z "${SETFILE_BIN}" ]]; then
  echo "error: SetFile not found; cannot set custom volume icon flag" >&2
  exit 1
fi
echo "  using SetFile: ${SETFILE_BIN}"
"${SETFILE_BIN}" -a C "${MOUNT_POINT}"
# Also flag the .VolumeIcon.icns file itself as having a custom icon —
# some Finder versions require both.
"${SETFILE_BIN}" -a C "${MOUNT_POINT}/.VolumeIcon.icns" 2>/dev/null || true
# Sanity check: confirm the kHasCustomIcon ('C') attribute is now set.
ATTRS=$("${SETFILE_BIN}" -a c "${MOUNT_POINT}" 2>/dev/null || true)
echo "  volume attributes: ${ATTRS}"

# Wait until Finder sees the volume (up to ~15s).
for _ in $(seq 1 30); do
  if osascript -e "tell application \"Finder\" to exists disk \"${ACTUAL_VOLNAME}\"" 2>/dev/null | grep -q true; then
    break
  fi
  sleep 0.5
done

# Window bounds are the OUTER frame including the title bar (~28pt). To make
# the 600x400 background image exactly fill the inner content area (so no
# scrollbar appears and the icons line up with the baked artwork), we add
# 28pt of title-bar height: height = 400 + 28 = 428.
osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "${ACTUAL_VOLNAME}"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 800, 548}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 128
    set text size of viewOptions to 13
    set background picture of viewOptions to POSIX file "${MOUNT_POINT}/.background/background.png"
    set position of item "BitTime.app" of container window to {150, 160}
    set position of item "Applications" of container window to {450, 160}
    update without registering applications
    delay 1
    close
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "${DEVICE}" -quiet || hdiutil detach "${DEVICE}" -force

hdiutil convert "${RAW_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_PATH}"
rm -f "${RAW_DMG}"

echo "==> Computing SHA-256 (dmg)"
shasum -a 256 "${DMG_PATH}" | tee "${DMG_PATH}.sha256"

# Resolve absolute paths for clear output.
ABS_APP_PATH=$(cd "$(dirname "${APP_PATH}")" && pwd)/$(basename "${APP_PATH}")
ABS_ZIP_PATH=$(cd "$(dirname "${ZIP_PATH}")" && pwd)/$(basename "${ZIP_PATH}")
ABS_DMG_PATH=$(cd "$(dirname "${DMG_PATH}")" && pwd)/$(basename "${DMG_PATH}")

echo
echo "==> Done"
echo "    App:       ${ABS_APP_PATH}"
echo "    Zip:       ${ABS_ZIP_PATH}"
echo "    Installer: ${ABS_DMG_PATH}"
