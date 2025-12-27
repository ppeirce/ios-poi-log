# POI Logger

A minimal iOS app for capturing nearby points of interest and exporting them as YAML for integration with Obsidian or other note-taking apps.

## Features

- **Capture Location**: Get your current GPS location
- **Find Nearby POIs**: Search for the 10 nearest points of interest within 0.5 miles
- **Sort by Distance**: Results automatically sorted by distance from your location
- **YAML Export**: Copy location data as structured YAML
- **Share Integration**: Share captured location data directly to Obsidian, Notes, Drafts, etc.
- **Fallback to Raw Coordinates**: If no POIs match, capture raw GPS coordinates

## Project Structure

```
POILog/
├── App.swift                    # Main app entry point
├── Models/
│   ├── POI.swift               # Point of Interest data model
│   └── LocationData.swift      # Location coordinate + timestamp
├── Services/
│   ├── LocationManager.swift   # CoreLocation wrapper, handles location requests
│   └── POISearchManager.swift  # MapKit local search for nearby POIs
└── Views/
    ├── ContentView.swift       # Main screen with Capture button
    ├── POIListView.swift       # List of nearby POIs
    └── YAMLPreviewView.swift   # Preview and share YAML data
```

## How It Works

1. **Request Location**: App requests `NSLocationWhenInUseUsageDescription` permission
2. **Capture**: Tap "Capture Location" to fetch your current GPS coordinates
3. **Search**: `POISearchManager` uses `MKLocalSearch` with a 0.5-mile region
4. **Filter & Sort**: Results are filtered by distance, sorted closest-first, limited to 10
5. **Select or Skip**:
   - Tap a POI to see its YAML representation
   - Tap "None of these" to use raw coordinates instead
6. **Copy/Share**: Use Copy button for clipboard, or Share button for other apps

## YAML Output Format

```yaml
date: 2025-12-27T09:12:00Z
name: Blue Bottle Coffee
address: 300 Webster St, Oakland, CA 94607
coordinates: 37.8012, -122.2727
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
- 0.5-mile (804.67m) search radius
- ISO8601 date format for timestamps

## Next Steps

To build and run:
1. Create an Xcode project with these files
2. Set a development team and bundle identifier
3. Enable "Maps" capability
4. Build for iOS 17+
