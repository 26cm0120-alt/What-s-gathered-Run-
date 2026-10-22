#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
# 日本語のプロジェクト名のUnicode正規化差を避け、実在するパスを使う。
set -- "$REPO_ROOT/"*.xcodeproj
if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "Xcodeプロジェクトを1つに特定できません" >&2
  exit 1
fi
PROJECT_PATH=$1
BUILD_OUTPUT_DIR=${BUILD_OUTPUT_DIR:-$(mktemp -d)}
mkdir -p "$BUILD_OUTPUT_DIR"

xcodebuild -version
# iOS 16を最小対象としたReleaseビルド。実機署名は不要。
# 出力先は毎回新規にし、古いresult bundleとの衝突を防ぐ。
RESULT_DIR=$(mktemp -d "$BUILD_OUTPUT_DIR/run-XXXXXX")
if xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme 'ワギャラン' \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$BUILD_OUTPUT_DIR/DerivedData" \
  -resultBundlePath "$RESULT_DIR/Build.xcresult" \
  IPHONEOS_DEPLOYMENT_TARGET=16.0 \
  CODE_SIGNING_ALLOWED=NO \
  build > "$RESULT_DIR/build.log" 2>&1; then
  tail -n 5 "$RESULT_DIR/build.log"
else
  tail -n 100 "$RESULT_DIR/build.log" >&2
  echo "ビルドログ: $RESULT_DIR/build.log" >&2
  exit 1
fi
echo "ビルドログ: $RESULT_DIR/build.log"
