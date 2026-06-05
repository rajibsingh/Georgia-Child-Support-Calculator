import SwiftUI

struct WelcomeView: View {
    var onDismiss: () -> Void
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            IntownColors.teal
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App icon / logo area
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.bottom, 28)

                Text("Working Numbers")
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundStyle(.white)

                Text("Georgia Family Law Calculator")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 4)

                Divider()
                    .background(.white.opacity(0.35))
                    .padding(.horizontal, 48)
                    .padding(.vertical, 32)

                VStack(spacing: 6) {
                    Text("Created by")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                    Text("Andrea Knight")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Intown Mediation")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.85))
                }

                VStack(spacing: 4) {
                    Text("(404) 588-3000")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                    Text("calendly.com/andreaknight")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.top, 16)

                Spacer()

                Text("© 2026 Intown Mediation LLC")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 8)

                Text("Tap to continue")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }
        .opacity(opacity)
        .onTapGesture {
            dismiss()
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) {
                opacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.35)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onDismiss()
        }
    }
}
