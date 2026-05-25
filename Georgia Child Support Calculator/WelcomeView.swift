import SwiftUI

struct WelcomeView: View {
    var onDismiss: () -> Void
    @State private var opacity = 1.0

    var body: some View {
        ZStack {
            Color(red: 0.282, green: 0.510, blue: 0.627) // #4782a0
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Created by Andrea Knight")
                    .font(.title2.weight(.semibold))
                Text("Intown Mediation")
                    .font(.title3)
                Text("To schedule mediation:")
                    .font(.body)
                    .padding(.top, 8)
                Text("(404) 588-3000")
                    .font(.body.weight(.medium))
                Text("calendly.com/andreaknight")
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(32)
        }
        .opacity(opacity)
        .onTapGesture {
            dismiss()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}
