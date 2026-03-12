#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_BASE="${1:-"$ROOT_DIR/dist"}"
PKG_DIR="$OUT_BASE/package"

cd "$ROOT_DIR"

if [[ -n "${ANDROID_HOME:-}" ]] && [[ ! -f local.properties ]]; then
  printf 'sdk.dir=%s\n' "$ANDROID_HOME" > local.properties
fi

rm -rf "$OUT_BASE"
mkdir -p "$PKG_DIR/lib"

./gradlew --no-daemon :lsplant:assembleRelease :test:assembleDebug

APK_PATH="$(find "$ROOT_DIR/test/build/outputs/apk/debug" -type f -name '*.apk' | head -n 1)"
if [[ -z "$APK_PATH" ]]; then
  echo "APK not found under test/build/outputs/apk/debug" >&2
  exit 1
fi

unzip -p "$APK_PATH" classes.dex > "$PKG_DIR/hook.dex"
unzip -q "$APK_PATH" 'lib/*' -d "$PKG_DIR/apk_extract"
if [[ -d "$PKG_DIR/apk_extract/lib" ]]; then
  cp -R "$PKG_DIR/apk_extract/lib/." "$PKG_DIR/lib/"
fi
rm -rf "$PKG_DIR/apk_extract"

while IFS= read -r so_path; do
  abi="$(basename "$(dirname "$so_path")")"
  mkdir -p "$PKG_DIR/lib/$abi"
  cp "$so_path" "$PKG_DIR/lib/$abi/liblsplant.so"
done < <(find "$ROOT_DIR/lsplant/build" -type f -name 'liblsplant.so' | sort -u)

if ! find "$PKG_DIR/lib" -type f -name 'liblsplant.so' | grep -q .; then
  echo "liblsplant.so not found in lsplant/build outputs" >&2
  exit 1
fi

VERSION="$(git describe --tags --always --dirty 2>/dev/null || git rev-parse --short HEAD)"
COMMIT="$(git rev-parse --short HEAD)"
REPO="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url)}"

cat > "$PKG_DIR/hook.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<hook-package>
  <source repo="${REPO}" commit="${COMMIT}" version="${VERSION}" />
  <dex path="hook.dex" />
  <native-libraries root="lib">
    <library name="liblsplant.so" />
    <library name="libtest.so" optional="false" />
    <library name="libdobby.so" optional="true" />
    <library name="libc++_shared.so" optional="true" />
  </native-libraries>
</hook-package>
EOF

ZIP_NAME="lsplant-hook-${VERSION}.zip"
(
  cd "$PKG_DIR"
  zip -qr "../$ZIP_NAME" hook.dex hook.xml lib
)

echo "Created $OUT_BASE/$ZIP_NAME"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "zip_path=$OUT_BASE/$ZIP_NAME"
    echo "zip_name=$ZIP_NAME"
  } >> "$GITHUB_OUTPUT"
fi
