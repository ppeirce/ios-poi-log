import SwiftUI
import CoreLocation

struct POIListView: View {
    let pois: [POI]
    let currentLocation: CLLocationCoordinate2D?
    @Binding var isPresented: Bool

    @State private var selectedPOI: POI?
    @State private var showYAMLPreview = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Nearby Places")
                        .font(.headline)
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
                            POIRowView(poi: poi)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPOI = poi
                                    showYAMLPreview = true
                                }
                        }
                    }
                    .listStyle(.plain)

                    Divider()

                    Button(action: { showYAMLPreview = true }) {
                        HStack {
                            Image(systemName: "exclamationmark.circle")
                            Text("None of these, use raw coordinates")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .foregroundColor(.orange)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showYAMLPreview) {
            if let poi = selectedPOI {
                YAMLPreviewView(poi: poi)
            } else {
                RawCoordinatesView(currentLocation: currentLocation)
            }
        }
    }
}

struct POIRowView: View {
    let poi: POI

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(poi.name)
                .font(.headline)
                .lineLimit(2)

            Text(poi.address)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(2)

            Text(poi.formattedDistance)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
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
