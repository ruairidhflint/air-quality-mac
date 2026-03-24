import SwiftUI

struct WelcomeView: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 32)

            Image("Icon")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .cornerRadius(20)
                .shadow(color: .primary.opacity(0.1), radius: 8, y: 4)

            Text("Welcome to Oxygenie")
                .font(.system(size: 26, weight: .bold))
                .padding(.top, 20)

            Text("Real-time local air quality, always in your menu bar.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 20) {
                featureRow(
                    icon: "menubar.arrow.up.rectangle",
                    title: "Lives in the menu bar",
                    detail: "Look for the AQI number or leaf icon at the top of your screen, near the clock. Click it to see details."
                )
                featureRow(
                    icon: "location.fill",
                    title: "Uses your location",
                    detail: "Oxygenie needs location access to fetch air quality for where you are. You'll be asked to allow this."
                )
                featureRow(
                    icon: "arrow.clockwise",
                    title: "Updates automatically",
                    detail: "Data refreshes every 15 minutes in the background. You can also refresh manually from the popover."
                )
            }
            .padding(.top, 28)
            .padding(.horizontal, 36)

            Spacer()

            Text("If your menu bar is full, the icon may be hidden. Click the \u{2039}\u{2039} arrow near the clock to find it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.bottom, 8)

            Button(action: onDismiss) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 36)
            .padding(.bottom, 28)
        }
        .frame(width: 420, height: 500)
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 28, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
