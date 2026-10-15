import SwiftUI

enum PlayerCutInStyle: Equatable {
    case wall
    case trap
    case encounter

    var imageName: String { self == .wall ? "PlayerBlink" : "PlayerIdle" }
    var accent: Color {
        switch self {
        case .wall: Color(red: 0.95, green: 0.48, blue: 0.22)
        case .trap: Color(red: 1.0, green: 0.76, blue: 0.24)
        case .encounter: Color(red: 0.55, green: 0.68, blue: 1.0)
        }
    }
    var showsTears: Bool { self == .wall }
    var showsAlert: Bool { self == .encounter }
}

/// 壁衝突・トラップ・敵との遭遇時に短く表示するPlayerのカットイン。
struct PlayerEventCutIn: View {
    let title: String
    let message: String
    let style: PlayerCutInStyle
    let animationFrame: String?
    let animationOffset: CGFloat
    let animationTilt: Double

    var body: some View {
        HStack(spacing: 14) {
            Image(animationFrame ?? style.imageName)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 104, height: 112)
                .offset(x: style == .trap ? animationOffset : 0)
                .rotationEffect(.degrees(style == .trap ? animationTilt : 0))
                .animation(.easeInOut(duration: 0.08), value: animationFrame)
                .overlay(alignment: .bottom) {
                    if style.showsTears {
                        HStack(spacing: 24) {
                            Image(systemName: "drop.fill").rotationEffect(.degrees(18))
                            Image(systemName: "drop.fill").rotationEffect(.degrees(-18))
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(red: 0.35, green: 0.78, blue: 1.0))
                        .shadow(color: .black.opacity(0.9), radius: 2, y: 1)
                        .offset(y: -25)
                        .accessibilityHidden(true)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if style.showsAlert {
                        Text("!")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(style.accent)
                            .shadow(color: .black, radius: 3, y: 2)
                            .offset(x: -8, y: 10)
                    }
                }
                .shadow(color: .black.opacity(0.65), radius: 5, y: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(2.4)
                    .foregroundStyle(style.accent)

                Text(message)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: style.accent.opacity(0.8), radius: 8)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 132)
        .background {
            ZStack {
                Color(red: 0.20, green: 0.025, blue: 0.045).opacity(0.96)
                LinearGradient(
                    colors: [style.accent.opacity(0.78), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                GeometryReader { geometry in
                    Path { path in
                        path.move(to: CGPoint(x: geometry.size.width * 0.78, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.9, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.72, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width * 0.6, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(Color.white.opacity(0.055))
                }
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(style.accent)
                .frame(height: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(style.accent.opacity(0.9), lineWidth: 1.5)
        }
        .shadow(color: .black.opacity(0.5), radius: 14, y: 8)
        .accessibilityElement(children: .combine)
    }
}
