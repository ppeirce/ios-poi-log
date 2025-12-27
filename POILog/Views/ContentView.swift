import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchManager = POISearchManager()
    @State private var showPOIList = false

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("POI Logger")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    if let coordinate = locationManager.currentLocation {
                        Text("Current Location")
                            .font(.headline)
                        Text(String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .monospaced()
                    } else {
                        Text("Waiting for location...")
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                if let error = locationManager.error {
                    Text("Location Error: \(error.localizedDescription)")
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button(action: captureLocation) {
                    if searchManager.isSearching {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching...")
                        }
                    } else {
                        Text("📍 Capture Location")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(locationManager.currentLocation != nil && !searchManager.isSearching ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(locationManager.currentLocation == nil || searchManager.isSearching)

                Spacer()
            }
            .padding()

            if showPOIList {
                POIListView(
                    pois: searchManager.nearbyPOIs,
                    currentLocation: locationManager.currentLocation,
                    isPresented: $showPOIList
                )
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: showPOIList) {
            if !showPOIList {
                searchManager.nearbyPOIs = []
            }
        }
    }

    private func captureLocation() {
        guard let coordinate = locationManager.currentLocation else { return }
        Task {
            await searchManager.searchNearbyPOIs(from: coordinate)
            withAnimation {
                showPOIList = true
            }
        }
    }
}

#Preview {
    ContentView()
}
