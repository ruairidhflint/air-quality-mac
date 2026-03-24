import Charts
import SwiftUI

extension Color {
    static let oxygenieMaroon = Color(red: 128 / 255, green: 0, blue: 0 / 255)
}

struct ContentView: View {
    @ObservedObject var viewModel: AirQualityViewModel
    var showAboutWindow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            Divider()

            if viewModel.isLoading, viewModel.airQualityData == nil {
                loadingView
            } else if let airQuality = viewModel.airQualityData {
                airQualitySummary(airQuality: airQuality)
                healthRecommendationBlock(aqi: airQuality.usAQI)
                segmentedAQIBar(value: airQuality.usAQI)
                pollutantRows(airQuality: airQuality)
                chartSection
            } else {
                Text("Waiting for air quality data…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.statusMessage.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                    Button("Retry") {
                        viewModel.refreshData()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Divider()
            footer
        }
        .frame(width: 320)
        .padding()
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.locationName ?? "Location")
                    .font(.headline)
                if let updated = viewModel.lastUpdated {
                    Text("Updated \(updated.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                viewModel.refreshData()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh air quality")
            .disabled(viewModel.isLoading)
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.85)
            Spacer()
        }
        .frame(height: 40)
    }

    private func airQualitySummary(airQuality: CurrentAirQuality) -> some View {
        let category = AQICategory.category(forUSAQI: airQuality.usAQI)
        return HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text("\(airQuality.usAQI)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(airQualityColor(for: airQuality.usAQI))
            VStack(alignment: .leading, spacing: 2) {
                Text("US AQI")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(category.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.bottom, 2)
        }
    }

    private func healthRecommendationBlock(aqi: Int) -> some View {
        let text = AQICategory.category(forUSAQI: aqi).healthRecommendation
        return Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Bar capped at 200 so “good” and “moderate” are more visible; values above still show full bar + numeric AQI.
    private func segmentedAQIBar(value: Int) -> some View {
        let cap = 200.0
        let fraction = min(Double(value) / cap, 1.0)
        return VStack(alignment: .leading, spacing: 6) {
            Text("Scale (0–\(Int(cap)), higher AQI in number above)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.green, .yellow, .orange, .red, .purple, Color.oxygenieMaroon],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(0.35)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(airQualityColor(for: value))
                        .frame(width: max(4, CGFloat(fraction) * geo.size.width), height: 10)
                }
            }
            .frame(height: 10)
        }
    }

    private func pollutantRows(airQuality: CurrentAirQuality) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pollutants")
                .font(.subheadline.weight(.semibold))
            airQualityRow(label: "PM10", value: airQuality.pm10, unit: "µg/m³")
            airQualityRow(label: "PM2.5", value: airQuality.pm2_5, unit: "µg/m³")
            airQualityRow(label: "Carbon Monoxide", value: airQuality.carbonMonoxide, unit: "µg/m³")
            airQualityRow(label: "Nitrogen Dioxide", value: airQuality.nitrogenDioxide, unit: "µg/m³")
            airQualityRow(label: "Sulphur Dioxide", value: airQuality.sulphurDioxide, unit: "µg/m³")
            airQualityRow(label: "Ozone", value: airQuality.ozone, unit: "µg/m³")
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        if viewModel.hourlyPoints.count >= 2 {
            VStack(alignment: .leading, spacing: 6) {
                Text("Last 24 hours (US AQI)")
                    .font(.subheadline.weight(.semibold))
                Chart(viewModel.hourlyPoints) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("AQI", point.usAQI)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(airQualityColor(for: viewModel.airQualityData?.usAQI ?? point.usAQI))
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value("AQI", point.usAQI)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [airQualityColor(for: viewModel.airQualityData?.usAQI ?? point.usAQI).opacity(0.35), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4))
                }
                .frame(height: 120)
            }
        }
    }

    private func airQualityRow(label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(value, specifier: "%.2f") \(unit)")
                .fontWeight(.medium)
        }
        .font(.caption)
    }

    private func airQualityColor(for value: Int) -> Color {
        switch value {
        case ...50:
            return .green
        case 51...100:
            return .yellow
        case 101...150:
            return .orange
        case 151...200:
            return .red
        case 201...300:
            return .purple
        default:
            return .oxygenieMaroon
        }
    }

    private var footer: some View {
        HStack {
            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .focusable(false)

            Spacer()

            Button("Info") {
                showAboutWindow()
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
    }
}
