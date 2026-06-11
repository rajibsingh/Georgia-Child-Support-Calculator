import SwiftUI

// Maximum content width — keeps layouts readable on iPad without going full-width.
let contentMaxWidth: CGFloat = 640

struct RootTabView: View {
    var body: some View {
        TabView {
            BallparkChildSupportView()
                .tabItem { Label("CS Ballpark", systemImage: "baseball.circle.fill") }
            ComingSoonView(title: "Detailed CS Estimator")
                .tabItem { Label("CS Estimator", systemImage: "list.bullet.circle.fill") }
            ComingSoonView(title: "Parenting Time Visualizer")
                .tabItem { Label("Visualizer", systemImage: "calendar.circle") }
            ComingSoonView(title: "Marital Property Equalizer", subtitle: "Calculate payment needed to equalize marital property.")
                .tabItem { Label("Equalizer", systemImage: "equal.circle.fill") }
            ThomasCalculatorView()
                .tabItem { Label("Thomas Calculator", systemImage: "divide.circle.fill") }
            ComingSoonView(title: "Pension Calculator")
                .tabItem { Label("Pension Calculator", systemImage: "function") }
        }
        // .automatic: bottom tab bar on iPhone, sidebar on iPad (iOS 18+)
        .tabViewStyle(.automatic)
        .tint(IntownColors.teal)
    }
}

struct ComingSoonView: View {
    var title: String
    var subtitle: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TabHeader(title: title, subtitle: subtitle)
                    CalculatorPanel("Coming Soon") {
                        VStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 48))
                                .foregroundStyle(IntownColors.teal)
                            Text("This tool is under development.")
                                .font(.body)
                                .foregroundStyle(IntownColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                }
                .contentWidth()
            }
            .background(IntownColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Shared per-tab header: title line + optional subheading + teal rule.
struct TabHeader: View {
    var title: String
    var subtitle: String? = nil
    var showPreviewBadge = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(IntownColors.teal)
                    .accessibilityAddTraits(.isHeader)
                if showPreviewBadge {
                    PreviewBadge()
                }
            }
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(IntownColors.secondaryText)
            }
            Rectangle()
                .fill(IntownColors.teal)
                .frame(height: 2)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(IntownColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Content width modifier

extension View {
    /// Constrains content to `contentMaxWidth`, centered, with standard page margins.
    func contentWidth() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .frame(maxWidth: contentMaxWidth)
            .frame(maxWidth: .infinity)
    }
}

struct PreviewBadge: View {
    var inverted = false

    var body: some View {
        Text("Preview")
            .font(.caption.weight(.medium))
            .foregroundStyle(inverted ? Color.white : IntownColors.teal)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(inverted ? Color.white.opacity(0.15) : IntownColors.teal.opacity(0.1))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(inverted ? Color.white.opacity(0.5) : IntownColors.teal.opacity(0.35), lineWidth: 1))
    }
}
