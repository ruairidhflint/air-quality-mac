import SwiftUI

struct AirQualityInfoView: View {
    let indicators: [(name: String, explanation: String)] = [
        ("AQI", "A standardized index that reports overall air quality by considering multiple pollutants."),
        ("PM10",  "Particulate matter with a diameter of 10 micrometers or less, including dust, pollen, and mold spores."),
        ("PM2.5",  "Fine particulate matter with a diameter of 2.5 micrometers or less, often resulting from combustion processes."),
        ("Carbon Monoxide", "A colorless, odorless gas produced by incomplete combustion of carbon-containing fuels."),
        ("Nitrogen Dioxide", "A reddish-brown gas primarily emitted from burning fossil fuels, contributing to smog and acid rain."),
        ("Sulphur Dioxide", "A colorless gas with a sharp odor, mainly produced by burning fossil fuels containing sulfur."),
        ("Ozone",  "A reactive gas composed of three oxygen atoms, beneficial in the upper atmosphere but harmful at ground level.")
    ]
    
    var body: some View {
        VStack(spacing: 10) {
            
            Image("Icon")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.5), radius: 5, x: 0, y: 2)
                .padding(.bottom, 10)
            
            Text("Oxygenie")
                .font(.system(size: 24, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .center)
            
            Text("Version 1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame( alignment: .center)
                .padding(.bottom, 10)
            
            ForEach(indicators, id: \.0) { indicator in
                HStack(alignment: .top, spacing: 10) {
                    Text(indicator.0)
                        .frame(width: 140, alignment: .leading)
                        .font(.system(size: 12, weight: .bold))
                    Text(indicator.1)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Divider()
                .padding(.vertical, 10)
            HStack(spacing: 4) {
                Text("Built by")
                Link("Rory Flint", destination: URL(string: "https://roryflint.co.uk")!).foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/).focusable(false)
            }
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
