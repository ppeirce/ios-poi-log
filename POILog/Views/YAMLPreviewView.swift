import SwiftUI
import CoreLocation
import MapKit

struct CheckInLogEntryView: View {
    let poi: POI
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var historyStore: CheckInHistoryStore

    @State private var didLogHistory = false
    @State private var mapPosition: MapCameraPosition

    init(poi: POI) {
        self.poi = poi
        _mapPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: poi.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        )
    }

    var captureData: CaptureData {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        return CaptureData(
            date: dateFormatter.string(from: now),
            time: timeFormatter.string(from: now),
            name: poi.name,
            address: poi.address,
            latitude: poi.coordinate.latitude,
            longitude: poi.coordinate.longitude
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("📍 \(poi.name)")
                        .font(.headline)
                        .lineLimit(2)

                    Text(poi.address)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(poi.formattedDistance)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                Map(position: $mapPosition) {
                    Marker(poi.name, coordinate: poi.coordinate)
                        .tint(.red)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    ShareLink(
                        item: captureData.yamlString,
                        subject: Text(poi.name),
                        message: Text("Location: \(poi.address)")
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.green)
                        .cornerRadius(8)
                    }

                    Button(action: checkIn) {
                        HStack(spacing: 6) {
                            Image(systemName: didLogHistory ? "checkmark.circle.fill" : "checkmark.circle")
                            Text(didLogHistory ? "Checked In" : "Check In")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(didLogHistory ? Color.orange.opacity(0.7) : Color.orange)
                        .cornerRadius(8)
                    }
                    .disabled(didLogHistory)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Check-In Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Back")
                    }
                }
            }
        }
    }

    private func checkIn() {
        guard !didLogHistory else { return }
        didLogHistory = true
        let record = CheckInRecord(
            name: poi.name,
            address: poi.address,
            latitude: poi.coordinate.latitude,
            longitude: poi.coordinate.longitude,
            category: poi.category
        )
        historyStore.add(record)
    }
}

struct RawCoordinatesView: View {
    let currentLocation: CLLocationCoordinate2D?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var historyStore: CheckInHistoryStore

    @State private var copied = false
    @State private var didLogHistory = false

    var captureData: CaptureData? {
        guard let location = currentLocation else { return nil }
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        return CaptureData(
            date: dateFormatter.string(from: now),
            time: timeFormatter.string(from: now),
            name: "Unknown Location",
            address: "",
            latitude: location.latitude,
            longitude: location.longitude
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let data = captureData {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📍 Raw Coordinates")
                            .font(.headline)

                        Text(String(format: "%.6f, %.6f", data.latitude, data.longitude))
                            .font(.caption)
                            .monospaced()
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("YAML")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        Text(data.yamlString)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    HStack(spacing: 12) {
                        Button(action: copyToClipboard) {
                            HStack(spacing: 6) {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copied" : "Copy YAML")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }

                    ShareLink(
                        item: data.yamlString,
                        message: Text("Raw coordinates")
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }

                Button(action: checkIn) {
                    HStack(spacing: 6) {
                        Image(systemName: didLogHistory ? "checkmark.circle.fill" : "checkmark.circle")
                        Text(didLogHistory ? "Checked In" : "Check In")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(didLogHistory ? Color.orange.opacity(0.7) : Color.orange)
                    .cornerRadius(8)
                }
                .disabled(didLogHistory || captureData == nil)
            } else {
                Text("Unable to get location")
                    .foregroundColor(.red)
            }

                Spacer()
            }
            .padding()
            .navigationTitle("Check-In Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Back")
                    }
                }
            }
        }
    }

    private func copyToClipboard() {
        guard let data = captureData else { return }
        UIPasteboard.general.string = data.yamlString
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }

    private func checkIn() {
        guard !didLogHistory, let location = currentLocation else { return }
        didLogHistory = true
        let record = CheckInRecord(
            name: "Unknown Location",
            address: "",
            latitude: location.latitude,
            longitude: location.longitude,
            category: nil
        )
        historyStore.add(record)
    }
}
