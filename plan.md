# Check In View Redesign - Implementation Plan

## Overview

Redesign the POI logging app from manual "Capture Location" workflow to an automatic "Check In" experience with integrated map + POI list, auto-fetch on app open/location ready, manual refresh, and a bottom tab layout.

**Key Changes:**
- Auto-fetch POIs when the app opens and a location is obtained
- Integrated view: Map (top) + POI list (bottom), no modal overlay
- Refresh button in nav bar (top-right) to re-request location; re-run POI search only if movement >150 ft (~46 m)
- Add bottom tabs: Check In, Visited (placeholder), Settings (future filters)
- Keep a lightweight coordinate readout (per ios-poi-log-343)
- Fix location staleness bug on app reopen (ios-poi-log-jx8)

---

## Architecture

### Component Structure
```
ContentView (TabView)
├── CheckInView (NavigationStack, main integrated view with auto-fetch)
│   ├── CurrentLocationMapView (Map with user location)
│   └── EmbeddedPOIListView (POI list for embedded display)
├── VisitedPlacesView (NavigationStack, placeholder for history)
└── SettingsView (NavigationStack, placeholder for filters)
```

### File Changes

**New Files:**
- `/Users/peter/projects/ios-poi-log/POILog/Views/CheckInView.swift` - Main integrated view
- `/Users/peter/projects/ios-poi-log/POILog/Views/CurrentLocationMapView.swift` - Map component
- `/Users/peter/projects/ios-poi-log/POILog/Views/EmbeddedPOIListView.swift` - POI list variant
- `/Users/peter/projects/ios-poi-log/POILog/Views/VisitedPlacesView.swift` - Placeholder tab for history
- `/Users/peter/projects/ios-poi-log/POILog/Views/SettingsView.swift` - Placeholder tab for filters

**Modified Files:**
- `/Users/peter/projects/ios-poi-log/POILog/Views/ContentView.swift` - TabView container
- `/Users/peter/projects/ios-poi-log/POILog/Services/LocationManager.swift` - Fix location refresh bug
- `/Users/peter/projects/ios-poi-log/POILog/Services/POISearchManager.swift` - Add concurrent search guard

---

## Implementation Details

### 1. Fix Location Refresh Bug (ios-poi-log-jx8)

**File:** `LocationManager.swift`

**Problem:** `hasRequestedLocation` flag prevents location from being re-requested on app reopen.

**Solution:** Allow repeated requests and trigger refresh on app open/foreground:
```swift
// REMOVE: private var hasRequestedLocation = false

func requestLocation() {
    locationManager.requestWhenInUseAuthorization()
    locationManager.requestLocation()
}

func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    DispatchQueue.main.async { [weak self] in
        self?.authorizationStatus = status
        // No one-time guard: requestLocation() controls explicit refreshes
    }
}
```
Then call `requestLocation()` on app open and when `scenePhase == .active` (and optionally clear stale `currentLocation` before requesting).

### 2. Create CurrentLocationMapView Component

**File:** `CurrentLocationMapView.swift`

**Features:**
- SwiftUI Map with MapCameraPosition
- UserAnnotation() for blue dot at user location
- MapUserLocationButton() and MapCompass() controls
- Auto-recenter on location change (`.onChange(of: currentLocation)`)
- Fixed height: 280pt

**Key Implementation:**
```swift
struct CurrentLocationMapView: View {
    let currentLocation: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition

    var body: some View {
        Map(position: $mapPosition) {
            if let location = currentLocation {
                UserAnnotation()
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onChange(of: currentLocation) { _, newValue in
            if let location = newValue {
                withAnimation {
                    mapPosition = .region(
                        MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                }
            }
        }
    }
}
```

### 3. Create CheckInView with Auto-Fetch

**File:** `CheckInView.swift`

**Layout:**
```swift
VStack(spacing: 0) {
    // Map Section (fixed height)
    CurrentLocationMapView(currentLocation: locationManager.currentLocation)
        .frame(height: 280)

    // Coordinate readout (compact)
    // e.g., Text("37.8012, -122.2727").font(.caption).monospaced()

    Divider()

    // POI List Section (flexible)
    if searchManager.isSearching {
        ProgressView("Finding nearby places...")
    } else {
        EmbeddedPOIListView(pois: searchManager.nearbyPOIs, ...)
    }
}
```

**Auto-Fetch + Skip Threshold:**
```swift
@State private var lastSearchLocation: CLLocation?
private let minSearchDistance: CLLocationDistance = 45.7 // ~150 ft

.onAppear {
    locationManager.requestLocation()
}
.onChange(of: locationManager.currentLocation) { _, newValue in
    guard let coordinate = newValue else { return }
    let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    if let last = lastSearchLocation, newLocation.distance(from: last) < minSearchDistance {
        isRefreshing = false
        return
    }
    lastSearchLocation = newLocation
    Task {
        await searchManager.searchNearbyPOIs(from: coordinate)
        isRefreshing = false
    }
}
```

**Refresh Button:**
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: handleRefresh) {
            if isRefreshing {
                ProgressView()
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(isRefreshing)
    }
}

private func handleRefresh() {
    isRefreshing = true
    locationManager.requestLocation()

    // Safety timeout
    Task {
        try? await Task.sleep(for: .seconds(10))
        isRefreshing = false
    }
}
```

### 4. Create EmbeddedPOIListView

**File:** `EmbeddedPOIListView.swift`

**Differences from POIListView:**
- No modal presentation chrome (no close button, no ZStack background)
- Just a List with POIRowView items
- Handle empty state inline
- Keep a raw-coordinate fallback action (placement: list footer or empty-state button)

**Implementation:**
```swift
struct EmbeddedPOIListView: View {
    let pois: [POI]
    let currentLocation: CLLocationCoordinate2D?
    let searchRadius: CLLocationDistance

    @State private var sheetContent: SheetContent?

    var body: some View {
        if pois.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "mappin.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("No nearby places found")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(pois) { poi in
                    POIRowView(poi: poi, searchRadius: searchRadius)
                        .onTapGesture {
                            sheetContent = .poiPreview(poi)
                        }
                }
            }
            .listStyle(.plain)
            .sheet(item: $sheetContent) { content in
                // Handle POI preview sheet
            }
        }
    }
}
```

### 5. Update ContentView

**File:** `ContentView.swift`

**Update to TabView container:**
```swift
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

            NavigationStack { VisitedPlacesView() }
                .tabItem { Label("Visited", systemImage: "clock") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                locationManager.requestLocation()
            }
        }
    }
}
```

### 6. Add Concurrent Search Guard

**File:** `POISearchManager.swift`

**Add guard to prevent duplicate searches:**
```swift
func searchNearbyPOIs(from coordinate: CLLocationCoordinate2D) async {
    guard !isSearching else { return } // Prevent concurrent searches
    isSearching = true
    // ... rest of implementation
}
```

---

## State Management

### Loading States

| Location Ready | POI Search | UI Display |
|---------------|-----------|------------|
| No | - | Map placeholder + "Getting your location..." |
| Yes | Searching | Map + "Finding nearby places..." |
| Yes | Complete (has POIs) | Map + POI list |
| Yes | Complete (empty) | Map + Empty state |
| Yes | Skipped (<150 ft) | Map + existing POI list (no refresh) |

### Error Handling

- **Location errors:** Show banner below map with settings link
- **POI search errors:** Show retry banner, enable refresh button
- **Permission denied:** Full-screen overlay with settings prompt

---

## Beads Workflow

### Epic Structure

**Epic:** Check In View Redesign with Auto-Fetch & Map Integration

**Sub-Issues:**
1. **ios-poi-log-jx8** - Fix location refresh on app reopen (LocationManager bug)
2. Add TabView with Settings + Visited placeholders
3. Create CurrentLocationMapView component
4. Extract CheckInView with auto-fetch logic + 150 ft skip
5. Create EmbeddedPOIListView variant
6. Update ContentView to TabView container
7. Integration testing & polish

**Implementation Sequence:**
- Phase 1: Sub-issues 1, 2 (foundation)
- Phase 2: Sub-issues 3, 4, 5 (core integration)
- Phase 3: Sub-issues 6, 7 (assembly & polish)

---

## Testing Checklist

**Location:**
- [ ] Fresh app install - location requested
- [ ] App reopen - location refreshed (jx8 fix)
- [ ] Permission denied - error displayed
- [ ] GPS unavailable - timeout handling

**POI Fetch:**
- [ ] Auto-fetch on location ready
- [ ] Refresh button updates POIs
- [ ] Refresh within 150 ft does not requery
- [ ] Refresh after >150 ft movement re-queries
- [ ] No POIs found - empty state shown
- [ ] Search error - error displayed

**Map:**
- [ ] User location displayed correctly
- [ ] Map re-centers on refresh
- [ ] Map controls functional

**Integration:**
- [ ] Tab navigation works (Check In / Visited / Settings)
- [ ] Rapid refresh taps (debouncing)
- [ ] App backgrounding/foregrounding
- [ ] Low connectivity scenarios

---

## Critical Files Summary

1. `LocationManager.swift` - Remove `hasRequestedLocation` guard + foreground refresh
2. `ContentView.swift` - TabView container
3. `CheckInView.swift` - New integrated view with auto-fetch + 150 ft skip
4. `CurrentLocationMapView.swift` - New map component
5. `EmbeddedPOIListView.swift` - New POI list variant
6. `VisitedPlacesView.swift` - Placeholder tab
7. `SettingsView.swift` - Placeholder tab
8. `POISearchManager.swift` - Add concurrent search guard
