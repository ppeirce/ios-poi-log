# Setup Guide

## Creating an Xcode Project

1. Open Xcode and create a new iOS app project
2. Choose **App** as the template
3. Set the product name to **POI Logger**
4. Select **SwiftUI** for the interface
5. Select **None** for storage (no CoreData)
6. Choose a Team ID and Bundle Identifier

## File Organization

After creating the project, organize files as follows:

```
POILog/
├── App.swift                    (Rename from main app file)
├── Models/
│   ├── POI.swift
│   └── LocationData.swift
├── Services/
│   ├── LocationManager.swift
│   └── POISearchManager.swift
├── Views/
│   ├── ContentView.swift
│   ├── POIListView.swift
│   └── YAMLPreviewView.swift
└── Info.plist                   (Update or create)
```

Copy all Swift files from this project into the corresponding Xcode folders.

## Xcode Project Settings

### Signing & Capabilities
1. Select the target
2. Go to **Signing & Capabilities**
3. Add **Maps** capability

### Info.plist
Replace the Info.plist with the provided `Info.plist` file, or add these keys:
- `NSLocationWhenInUseUsageDescription`: "We need your location to find nearby points of interest for your log."
- `NSLocationAlwaysAndWhenInUseUsageDescription`: Same as above (if supporting location always)
- `UIRequiredDeviceCapabilities`: Add `location-services`

### Build Settings
- Minimum deployment: **iOS 17.0**
- Swift version: **6.0+**

## Testing

1. Run on simulator or device
2. When prompted, approve location access (When Using the App)
3. Tap "Capture Location"
4. Select a POI from the list or choose "None of these"
5. Copy YAML or share to another app

## Troubleshooting

**Location not updating**: Ensure location permissions are granted. Go to Settings > POI Logger > Location.

**No POIs found**: The search radius is 0.5 miles. Try in an area with more POI data (urban areas work better).

**MapKit errors**: Verify the Maps capability is enabled in Signing & Capabilities.
