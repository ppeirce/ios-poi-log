import SwiftUI

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchManager = POISearchManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            NavigationStack {
                CheckInView(
                    locationManager: locationManager,
                    searchManager: searchManager
                )
            }
            .tabItem { Label("Check In", systemImage: "mappin.and.ellipse") }

            NavigationStack {
                VisitedPlacesView()
            }
            .tabItem { Label("Visited", systemImage: "clock") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .task {
            locationManager.requestLocation()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                locationManager.requestLocation()
            }
        }
    }
}

#Preview {
    ContentView()
}
