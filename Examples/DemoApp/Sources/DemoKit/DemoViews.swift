import SwiftUI
import SnapPreferences

// A small feature module whose previews are the demo payload. The views use
// explicit frames and their own backgrounds so the exported PNGs are
// self-contained images rather than transparent outlines.

public struct PlayerCard: View {
    let playerName: String
    let level: Int
    let progress: Double

    public init(playerName: String, level: Int, progress: Double) {
        self.playerName = playerName
        self.level = level
        self.progress = progress
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.25))
                        .frame(width: 52, height: 52)
                    Text(String(playerName.prefix(1)))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(playerName)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Level \(level)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.9))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.25))
                    Capsule()
                        .fill(.white.opacity(0.9))
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 8)

            Text("\(Int(progress * 100))% to next level")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(20)
        .frame(width: 340, height: 150)
        .background(
            LinearGradient(
                colors: [.indigo, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

public struct AchievementRow: View {
    let title: String
    let detail: String
    let isUnlocked: Bool

    public init(title: String, detail: String, isUnlocked: Bool) {
        self.title = title
        self.detail = detail
        self.isUnlocked = isUnlocked
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                .font(.system(size: 18))
                .foregroundStyle(isUnlocked ? Color.green : Color.secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isUnlocked {
                Text("Unlocked")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15), in: Capsule())
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

public enum SyncStatus {
    case syncing
    case failed(String)
}

public struct SyncStatusBanner: View {
    let status: SyncStatus

    public init(status: SyncStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 10) {
            switch status {
            case .syncing:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.blue)
                Text("Syncing workspace…")
            case .failed(let reason):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(reason)
            }
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(width: 320)
        .background(
            (status.isFailure ? Color.orange.opacity(0.12) : Color.blue.opacity(0.12))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

public struct InteractiveCounter: View {
    @State private var count = 0

    public init() {}

    public var body: some View {
        HStack(spacing: 18) {
            Button {
                count -= 1
            } label: {
                Image(systemName: "minus")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Decrease Count")

            VStack(spacing: 2) {
                Text(count, format: .number)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("Count")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 64)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Count")
            .accessibilityValue(count.formatted())

            Button {
                count += 1
            } label: {
                Image(systemName: "plus")
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Increase Count")
        }
        .padding(24)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension SyncStatus {
    var isFailure: Bool {
        if case .failed = self {
            return true
        }
        return false
    }
}

// MARK: - Previews

#Preview("Player Card") {
    PlayerCard(playerName: "Oakhaven", level: 12, progress: 0.72)
        .padding(24)
}

#Preview("Player Card Dark") {
    PlayerCard(playerName: "Oakhaven", level: 12, progress: 0.72)
        .padding(24)
        .preferredColorScheme(.dark)
}

#Preview("Achievement Row") {
    VStack(spacing: 8) {
        AchievementRow(
            title: "Cartographer",
            detail: "Author 10 complete maps",
            isUnlocked: true
        )
        AchievementRow(
            title: "Sound Weaver",
            detail: "Author bounded audio for every region",
            isUnlocked: false
        )
    }
    .padding(24)
}

#Preview("Sync Banner Failed") {
    SyncStatusBanner(status: .failed("The audio source cannot be decoded as bounded Ogg Vorbis."))
        .padding(24)
        .snapTags(["screen": "sync", "severity": "error"])
        .snapDiffThreshold(0.02)
        .snapAdditionalContext(["fixture": "vorbis-refusal"])
}

#Preview("Interactive Counter") {
    InteractiveCounter()
        .padding(24)
        .snapTags(["component": "counter", "interaction": "stateful"])
        .snapAdditionalContext(["reset_behavior": "fresh-instance"])
}
