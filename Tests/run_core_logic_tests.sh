#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT
TEST_BINARY="$BUILD_DIR/wagyaran-core-tests"

swiftc \
  -parse-as-library \
  -swift-version 5 \
  -default-isolation MainActor \
  -o "$TEST_BINARY" \
  "$REPO_ROOT/Map/Core/Direction.swift" \
  "$REPO_ROOT/Map/Core/GridPos.swift" \
  "$REPO_ROOT/Map/Core/Leaderboard.swift" \
  "$REPO_ROOT/Map/Core/StageTimingPolicy.swift" \
  "$REPO_ROOT/Map/Events/EnemyKind.swift" \
  "$REPO_ROOT/Map/Events/TrapSelection.swift" \
  "$REPO_ROOT/Map/Stage/MapCell.swift" \
  "$REPO_ROOT/Map/Stage/MapData.swift" \
  "$REPO_ROOT/Map/Stage/MapLoader.swift" \
  "$REPO_ROOT/Map/Stage/RandomMazeGenerator.swift" \
  "$REPO_ROOT/Map/Stage/Stages.swift" \
  "$REPO_ROOT/Tests/Support/AudioResourceStub.swift" \
  "$REPO_ROOT/Tests/CoreLogicTests.swift"

FIRST_SIGNATURE=$("$TEST_BINARY" --determinism-probe | shasum -a 256)
SECOND_SIGNATURE=$("$TEST_BINARY" --determinism-probe | shasum -a 256)
if [ "$FIRST_SIGNATURE" != "$SECOND_SIGNATURE" ]; then
  echo "失敗: 別プロセス間で同じseedの生成結果が一致しません" >&2
  exit 1
fi

"$TEST_BINARY"
echo "PASS: 別プロセス間のseed再現性 (256 seeds)"
