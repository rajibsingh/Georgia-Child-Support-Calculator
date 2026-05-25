import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Child Support Ballparker", systemImage: "baseball.circle.fill") {
                BallparkChildSupportView()
            }
            Tab("Detailed CS Estimate", systemImage: "list.bullet.circle.fill") {
                ComingSoonView(title: "Detailed CS Estimate")
            }
            Tab("Parenting Time Visualizer", systemImage: "calendar.circle") {
                ComingSoonView(title: "Parenting Time Visualizer")
            }
            Tab("MP Equalizer", systemImage: "equal.circle.fill") {
                ComingSoonView(title: "MP Equalizer", subtitle: "Calculate payment needed to equalize marital property.")
            }
            Tab("Thomas Calculator", systemImage: "divide.circle.fill") {
                ThomasCalculatorView()
            }
            Tab("Pension Calculator", systemImage: "function") {
                ComingSoonView(title: "Pension Calculator")
            }
        }
        .tabViewStyle(.automatic)
        // Hide tab labels — icons only
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
        }
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
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(IntownColors.teal)
                .accessibilityAddTraits(.isHeader)
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
