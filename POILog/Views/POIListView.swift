import SwiftUI
import CoreLocation
import MapKit

struct POIListView: View {
    let pois: [POI]
    let currentLocation: CLLocationCoordinate2D?
    let searchRadius: CLLocationDistance
    @Binding var isPresented: Bool

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
        ZStack(alignment: .top) {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Nearby Places")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))

                if pois.isEmpty {
                    EmptyStateView(currentLocation: currentLocation, onDismiss: { isPresented = false })
                } else {
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
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)

                    Divider()

                    Button(action: { sheetContent = .rawCoordinates }) {
                        Label("None of these, use raw coordinates", systemImage: "exclamationmark.circle")
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .foregroundColor(.orange)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding()
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
}

struct POIRowView: View {
    let poi: POI
    let searchRadius: CLLocationDistance

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(poi.name)
                    .font(.headline)
                    .lineLimit(2)

                if let category = poi.category {
                    Text(category)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.14))
                        .clipShape(Capsule())
                }

                Text(poi.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Label(poi.formattedDistance, systemImage: "location.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Map(position: .constant(mapPosition), interactionModes: []) {
                Marker(poi.name, coordinate: poi.coordinate)
                    .tint(.red)
            }
            .frame(width: 76, height: 76)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    private var region: MKCoordinateRegion {
        let baseSpanDelta: CLLocationDegrees = 0.002
        let scale = searchRadius / POISearchManager.defaultSearchRadius
        let delta = baseSpanDelta * scale
        return MKCoordinateRegion(
            center: poi.coordinate,
            span: MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        )
    }

    private var mapPosition: MapCameraPosition {
        .region(region)
    }
}

struct EmptyStateView: View {
    let currentLocation: CLLocationCoordinate2D?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No places found nearby")
                .font(.headline)

            Text("No points of interest found within 0.5 miles.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button(action: onDismiss) {
                Text("Try again")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()

            Spacer()
        }
        .padding()
    }
}
