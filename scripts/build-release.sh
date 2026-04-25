#!/usr/bin/env bash
#
# Build BitTime.app and produce dist/BitTime-<version>.zip.
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

echo "==> Computing SHA-256"
shasum -a 256 "${ZIP_PATH}" | tee "${ZIP_PATH}.sha256"

echo "==> Done: ${ZIP_PATH}"
