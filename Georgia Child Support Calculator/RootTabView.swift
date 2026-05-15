import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Tab("Ballpark CS", systemImage: "dollarsign.circle") {
                BallparkChildSupportView()
            }
            Tab("Thomas Calc", systemImage: "house") {
                ThomasCalculatorView()
            }
            Tab("Detailed CS", systemImage: "list.bullet.rectangle") {
                ComingSoonView(title: "Detailed Child Support")
            }
            Tab("Parenting Time", systemImage: "calendar") {
                ComingSoonView(title: "Parenting Time Visualizer")
            }
            Tab("More", systemImage: "ellipsis.circle") {
                MoreMenuView()
            }
        }
        .tint(IntownColors.teal)
    }
}

/// Overflow menu for the two least-frequently-used coming-soon tools.
struct MoreMenuView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Marital Balance Sheet") {
                    ComingSoonView(title: "Marital Balance Sheet")
                }
                NavigationLink("Pension Calculator") {
                    ComingSoonView(title: "Pension Calculator")
                }
            }
            .navigationTitle("More Tools")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ComingSoonView: View {
    var title: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "clock")
                    .font(.system(size: 48))
                    .foregroundStyle(IntownColors.teal)
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(IntownColors.text)
                Text("Coming soon.")
                    .font(.body)
                    .foregroundStyle(IntownColors.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(IntownColors.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
