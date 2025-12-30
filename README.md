# POI Logger

A minimal iOS app for checking in to nearby points of interest, exporting YAML, and keeping a personal visit log with JSON/CSV exports.

## Features

- **Check In Flow**: Auto-request location and fetch nearby POIs
- **Find Nearby POIs**: Filter by category within a 5-mile (8040.67m) radius
- **Category Filters**: Defaults to Restaurants + Nightlife, configurable in Settings
- **YAML Export**: Copy or share structured YAML with 6-decimal coordinates
- **Visited History**: See past check-ins with a map overview
- **JSON/CSV Export**: Share history from the Visited tab
- **Debug Mode**: Show diagnostics and search from map center
- **Fallback to Raw Coordinates**: Log raw GPS coordinates when needed

## Project Structure

```
POILog/
├── App.swift                    # Main app entry point
├── Models/
│   ├── POI.swift               # Point of Interest data model
│   └── LocationData.swift      # Location coordinate + timestamp
├── Services/
│   ├── LocationManager.swift   # CoreLocation wrapper, handles location requests
│   ├── POISearchManager.swift  # MapKit local search for nearby POIs
│   └── CheckInHistoryStore.swift # Local history persistence + export
└── Views/
    ├── ContentView.swift       # Tabbed navigation root
    ├── CheckInView.swift       # Primary check-in flow
    ├── EmbeddedPOIListView.swift # Nearby POI list + refresh
    ├── YAMLPreviewView.swift   # YAML preview + map + share
    ├── VisitedPlacesView.swift # History list + exports
    └── SettingsView.swift      # Category + debug settings
```

## How It Works

1. **Request Location**: App requests `NSLocationWhenInUseUsageDescription` permission
2. **Check In**: Location is requested on launch and when returning to the app
3. **Search**: `POISearchManager` uses `MKLocalSearch` within 5 miles (8040.67m)
4. **Filter & Sort**: Results are filtered by category and distance, sorted closest-first
5. **Select or Skip**:
   - Tap a POI to view YAML and a map preview
   - Tap "Use raw coordinates" to log GPS only
6. **Copy/Share**: Copy or share YAML, or press "Check In" to add history
7. **Review History**: Visit the Visited tab to search, filter dates, and export JSON/CSV

## YAML Output Format

```yaml
date: 2025-12-27
time: 09:12
name: Blue Bottle Coffee
address: 300 Webster St, Oakland, CA 94607
coordinates: 37.801200, -122.272700
```

## Build Requirements

- Xcode 16.0+
- iOS 17.0+
- Swift 6.0+

## Key Dependencies

- **SwiftUI**: UI framework
- **MapKit**: Local POI search
- **CoreLocation**: GPS location services
- **Combine**: Reactive data updates

## Configuration

The app uses:
- `NSLocationWhenInUseUsageDescription` for on-demand location access
- `MKLocalSearch` with `.pointOfInterest` result type
- 5-mile (8040.67m) search radius
- Category filtering with defaults to Restaurants + Nightlife
- Optional debug mode diagnostics
- Date + time fields in YAML with 6-decimal coordinates

## Next Steps

To build and run:
1. Open `POILog.xcodeproj` in Xcode
2. Set a development team and bundle identifier
3. Enable "Maps" capability
4. Build for iOS 17+
