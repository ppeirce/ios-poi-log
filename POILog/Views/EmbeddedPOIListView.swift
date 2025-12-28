import SwiftUI
import CoreLocation

struct EmbeddedPOIListView: View {
    let pois: [POI]
    let currentLocation: CLLocationCoordinate2D?
    let searchRadius: CLLocationDistance
    let onRefresh: () async -> Void

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
                emptyState
            } else {
                listContent
            }
        }
        .sheet(item: $sheetContent) { content in
            switch content {
            case .poiPreview(let poi):
                YAMLPreviewView(poi: poi)
            case .rawCoordinates:
                RawCoordinatesView(currentLocation: currentLocation)
            }
        }
    }

    private var listContent: some View {
        List {
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

            if currentLocation != nil {
                Button(action: { sheetContent = .rawCoordinates }) {
                    Label("Use raw coordinates", systemImage: "exclamationmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .foregroundColor(.orange)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            await onRefresh()
        }
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "mappin.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("No nearby places found")
                    .foregroundColor(.secondary)

                if currentLocation != nil {
                    Button(action: { sheetContent = .rawCoordinates }) {
                        Label("Use raw coordinates", systemImage: "exclamationmark.circle")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .foregroundColor(.orange)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .refreshable {
            await onRefresh()
        }
    }
}

#Preview {
    EmbeddedPOIListView(
        pois: [],
        currentLocation: CLLocationCoordinate2D(latitude: 37.8012, longitude: -122.2727),
        searchRadius: POISearchManager.defaultSearchRadius,
        onRefresh: {}
    )
}
