import SwiftUI

struct LandingView: View {
    /// RootView tells us what to do when the user taps "Get Started"
    let onGetStarted: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.57, blue: 0.98),
                    Color(red: 0.36, green: 0.79, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("Simple Weather")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)

                Text("Track your favourite cities with clean, beautiful forecasts.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 32)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.yellow)
                    .padding(30)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                    )
                    .padding(.top, 8)

                featureCard

                Spacer()

                // ⬇️ Button instead of NavigationLink
                Button {
                    onGetStarted()
                } label: {
                    HStack(spacing: 8) {
                        Text("Get Started")
                            .font(.headline)
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(24)
                    .padding(.horizontal, 32)
                }

                Spacer().frame(height: 32)
            }
        }
    }

    // MARK: - Feature card

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why you'll love Simple Weather")
                .font(.headline)
                .foregroundColor(.white)

            featureRow(icon: "list.bullet",
                       text: "Save multiple cities and switch between them instantly.")
            featureRow(icon: "arrow.clockwise.circle",
                       text: "Pull to refresh and get the latest live data.")
            featureRow(icon: "cloud.sun.fill",
                       text: "Enjoy a clean layout with detailed conditions.")
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.18))
        )
        .padding(.horizontal, 24)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.white)

            Text(text)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.95))
        }
    }
}
