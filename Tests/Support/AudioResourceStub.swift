/// Stage型の純粋ロジックをコマンドラインで検証するための音源名スタブ。
enum AudioResource {
    case wallCollision
    case movement
    case enemyDefeat
    case templeBGM
    case caveBGM
    case hellBGM
    case forestMansionBGM
    case slimeCounterattack
    case skeletonCounterattack
    case gargoyleCounterattack
    case impCounterattack
    case ghostCounterattack
    case cyclopsCounterattack
    case mimicCounterattack
    // グループAのトラップ効果音
    case trapTurn
    case trapSlowFlick
    case trapPoison
}

/// ゲームロジックのテストでは端末の音声出力だけを省略する。
final class SoundEffectController {
    func play(_ resource: AudioResource) {}
}
