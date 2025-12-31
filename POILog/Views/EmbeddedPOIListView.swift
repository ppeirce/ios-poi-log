import SwiftUI
import CoreLocation

struct EmbeddedPOIListView: View {
    let pois: [POI]
    let currentLocation: CLLocationCoordinate2D?
    let searchRadius: CLLocationDistance
    let searchText: String

    @State private var sheetContent: SheetContent?

    enum SheetContent: Identifiable {
        case poiPreview(POI)
        case rawCoordinates

        var id: String {
            switch self {
            case .poiPreview(let poi): return poi.id.uuidString
            case .rawCoordinates: return "raw"
            }
        }
    }

    var body: some View {
        Group {
            if pois.isEmpty {
                if isSearchActive {
                    noMatchesRow
                } else {
                    emptyStateRow
                }
            } else {
                poiRows

                if currentLocation != nil {
                    rawCoordinatesRow
                }
            }
        }
        .sheet(item: $sheetContent) { content in
            switch content {
            case .poiPreview(let poi):
                CheckInLogEntryView(poi: poi)
            case .rawCoordinates:
                RawCoordinatesView(currentLocation: currentLocation)
            }
        }
    }

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var poiRows: some View {
        ForEach(pois) { poi in
            POIRowView(poi: poi, searchRadius: searchRadius)
                .contentShape(Rectangle())
                .onTapGesture {
                    sheetContent = .poiPreview(poi)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
        }
    }

    private var rawCoordinatesRow: some View {
        rawCoordinatesButton
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 12, trailing: 16))
            .listRowBackground(Color.clear)
    }

    private var rawCoordinatesButton: some View {
        Button(action: { sheetContent = .rawCoordinates }) {
            Label("Use raw coordinates", systemImage: "exclamationmark.circle")
                .frame(maxWidth: .infinity)
                .padding(12)
                .foregroundColor(.orange)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var emptyStateRow: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No nearby places found")
                .foregroundColor(.secondary)

            if currentLocation != nil {
                rawCoordinatesButton
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
    }

    private var noMatchesRow: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.secondary)

            Text("No matches")
                .font(.headline)

            Text("Try a different search or use raw coordinates.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if currentLocation != nil {
                rawCoordinatesButton
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
    }
}

#Preview {
    EmbeddedPOIListView(
        pois: [],
        currentLocation: CLLocationCoordinate2D(latitude: 37.8012, longitude: -122.2727),
        searchRadius: POISearchManager.defaultSearchRadius,
        searchText: ""
    )
}
