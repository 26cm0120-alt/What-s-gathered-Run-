#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT
TEST_BINARY="$BUILD_DIR/wagyaran-core-tests"

xcrun swiftc \
  -parse-as-library \
  -swift-version 5 \
  -default-isolation MainActor \
  -D DEBUG \
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
  "$REPO_ROOT/Map/Core/GameManager.swift" \
  "$REPO_ROOT/Map/Core/GameState.swift" \
  "$REPO_ROOT/Map/Core/Player.swift" \
  "$REPO_ROOT/Map/Events/TileEvent.swift" \
  "$REPO_ROOT/Map/Events/Trap.swift" \
  "$REPO_ROOT/Map/Events/Key.swift" \
  "$REPO_ROOT/Map/Events/Enemy.swift" \
  "$REPO_ROOT/Map/Shiritori/Models/Card.swift" \
  "$REPO_ROOT/Map/Shiritori/Models/Vocabulary.swift" \
  "$REPO_ROOT/Map/Shiritori/Models/WordType.swift" \
  "$REPO_ROOT/Map/Shiritori/Game/Turn.swift" \
  "$REPO_ROOT/Map/Shiritori/Game/ShiritoriGameState.swift" \
  "$REPO_ROOT/Map/Shiritori/Game/GameResult.swift" \
  "$REPO_ROOT/Map/Shiritori/Game/ShiritoriGameManager.swift" \
  "$REPO_ROOT/Map/Shiritori/Logic/KanaNormalizer.swift" \
  "$REPO_ROOT/Map/Shiritori/Logic/VocabularySelector.swift" \
  "$REPO_ROOT/Map/Shiritori/Logic/CPUSelector.swift" \
  "$REPO_ROOT/Map/Shiritori/Logic/CPUScanState.swift" \
  "$REPO_ROOT/Map/Shiritori/Logic/MessageSelector.swift" \
  "$REPO_ROOT/Map/Shiritori/Data/CardData.swift" \
  "$REPO_ROOT/Map/Shiritori/Data/CardData2.swift" \
  "$REPO_ROOT/Tests/Support/SoundEffectManagerStub.swift" \
  "$REPO_ROOT/Tests/ShiritoriLogicTests.swift" \
  "$REPO_ROOT/Tests/ShiritoriGameManagerTests.swift" \
  "$REPO_ROOT/Tests/GameManagerTests.swift" \
  "$REPO_ROOT/Tests/CoreLogicTests.swift"

FIRST_SIGNATURE=$("$TEST_BINARY" --determinism-probe | shasum -a 256)
SECOND_SIGNATURE=$("$TEST_BINARY" --determinism-probe | shasum -a 256)
if [ "$FIRST_SIGNATURE" != "$SECOND_SIGNATURE" ]; then
  echo "失敗: 別プロセス間で同じseedの生成結果が一致しません" >&2
  exit 1
fi

"$TEST_BINARY"
echo "PASS: 別プロセス間のseed再現性 (256 seeds)"
