import SwiftUI

struct AirQualityInfoView: View {
    let indicators: [(name: String, explanation: String)] = [
        ("AQI", "Environmental Quality Index: Overall air quality measure"),
        ("PM10",  "Particulate Matter up to 10 micrometers: Dust, pollen, mold"),
        ("PM2.5",  "Fine Particulate Matter up to 2.5 micrometers: Smoke, haze"),
        ("Carbon Monoxide", "Colorless, odorless gas from incomplete combustion"),
        ("Nitrogen Dioxide", "Reddish-brown gas from vehicle emissions and industry"),
        ("Sulphur Dioxide", "Colorless gas with sharp odor from fossil fuel combustion"),
        ("Ozone",  "Bluish gas formed by chemical reactions between pollutants")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Air Quality")
                .font(.system(size: 24, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .center)
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
            
            Text("Air quality indicators provide crucial information about the composition and safety of the air we breathe.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

//struct AirQualityInfoView_Previews: PreviewProvider {
//    static var previews: some View {
//        AirQualityInfoView()
//    }
//}
