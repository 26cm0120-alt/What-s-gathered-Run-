import SwiftUI

/// BGMと効果音の音量をスライダーで調整する設定画面。値はその場でUserDefaultsへ保存する。
struct AudioSettingsView: View {
    /// 音量が変わるたびに呼ばれる。再生中のBGMへ反映するために使う。
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var backgroundMusic = Double(AudioVolumeSettings.backgroundMusic)
    @State private var soundEffect = Double(AudioVolumeSettings.soundEffect)
    /// 効果音スライダーを離したときの試聴用
    @State private var previewEffects = SoundEffectController()

    private let gold = Color(red: 0.89, green: 0.78, blue: 0.49)

    var body: some View {
        ZStack {
            DungeonBackground()

            VStack(spacing: 22) {
                Text("音量設定")
                    .font(DungeonTypography.maruMonica(size: 28))
                    .foregroundStyle(gold)
                    .padding(.top, 28)

                volumeRow(title: "BGM", symbol: "music.note", value: backgroundMusic, binding: backgroundMusicBinding)
                volumeRow(
                    title: "効果音",
                    symbol: "speaker.wave.2.fill",
                    value: soundEffect,
                    binding: soundEffectBinding,
                    onEditingChanged: { editing in
                        // スライダーを離したときに、効果音の大きさを確かめられるようにする。
                        if !editing { previewEffects.play(.battleAttack) }
                    }
                )

                Button("初期値に戻す") {
                    backgroundMusicBinding.wrappedValue = Double(AudioVolumeSettings.defaultVolume)
                    soundEffectBinding.wrappedValue = Double(AudioVolumeSettings.defaultVolume)
                }
                .font(DungeonTypography.maruMonica(size: 17))
                .foregroundStyle(Color.white.opacity(0.8))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("閉じる")
                        .font(DungeonTypography.maruMonica(size: 20))
                        .foregroundStyle(gold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.67, green: 0.57, blue: 0.36).opacity(0.55), lineWidth: 1)
                        }
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 24)
        }
        .preferredColorScheme(.dark)
    }

    private var backgroundMusicBinding: Binding<Double> {
        Binding(
            get: { backgroundMusic },
            set: { newValue in
                backgroundMusic = newValue
                AudioVolumeSettings.save(Float(newValue), forKey: AudioVolumeSettings.backgroundMusicKey)
                onChange()
            }
        )
    }

    private var soundEffectBinding: Binding<Double> {
        Binding(
            get: { soundEffect },
            set: { newValue in
                soundEffect = newValue
                AudioVolumeSettings.save(Float(newValue), forKey: AudioVolumeSettings.soundEffectKey)
                onChange()
            }
        )
    }

    private func volumeRow(
        title: String,
        symbol: String,
        value: Double,
        binding: Binding<Double>,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: symbol)
                    .font(DungeonTypography.maruMonica(size: 20))
                    .foregroundStyle(Color.white.opacity(0.92))
                Spacer()
                Text("\(Int((value * 100).rounded()))%")
                    .font(DungeonTypography.maruMonica(size: 20))
                    .foregroundStyle(gold)
                    .monospacedDigit()
            }
            Slider(value: binding, in: 0...1, onEditingChanged: onEditingChanged)
                .tint(gold)
                .accessibilityLabel("\(title)の音量")
        }
        .padding(14)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.67, green: 0.57, blue: 0.36).opacity(0.48), lineWidth: 1)
        }
    }
}
