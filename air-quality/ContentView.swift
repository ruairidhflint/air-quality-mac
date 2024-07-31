import SwiftUI
import CoreLocation

struct ContentView: View {
    @ObservedObject var viewModel: LocationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            if viewModel.isLoading {
                loadingView
            } else if let airQuality = viewModel.airQualityData {
                airQualityView(airQuality: airQuality)
            } else {
                Text("Waiting for air quality data...")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
        }
        .frame(width: 300 )
        .padding()
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.locationName ?? "Location")
                .font(.headline)
            
            Text(viewModel.status)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 20, height: 20)
            Spacer()
        }
    }
    
    private func airQualityView(airQuality: CurrentAirQuality) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            airQualityMeter(value: airQuality.europeanAQI)
            
            Group {
                airQualityRow(label: "PM10", value: airQuality.pm10, unit: "µg/m³")
                airQualityRow(label: "PM2.5", value: airQuality.pm2_5, unit: "µg/m³")
                airQualityRow(label: "Carbon Monoxide", value: airQuality.carbonMonoxide, unit: "µg/m³")
                airQualityRow(label: "Nitrogen Dioxide", value: airQuality.nitrogenDioxide, unit: "µg/m³")
                airQualityRow(label: "Sulphur Dioxide", value: airQuality.sulphurDioxide, unit: "µg/m³")
                airQualityRow(label: "Ozone", value: airQuality.ozone, unit: "µg/m³")
            }
        }
    }
    
    private func airQualityMeter(value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Air Quality Index")
                .font(.headline)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                Rectangle()
                    .fill(airQualityColor(for: value))
                    .frame(width: CGFloat(value) / 100 * 300, height: 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)

        }
    }
    
    private func airQualityRow(label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value, specifier: "%.2f") \(unit)")
                .fontWeight(.medium)
        }
    }
    
    private func airQualityColor(for value: Int) -> Color {
        switch value {
        case 0...50: return .green
        case 51...100: return .yellow
        case 101...150: return .orange
        case 151...200: return .red
        default: return .purple
        }
    }
}
