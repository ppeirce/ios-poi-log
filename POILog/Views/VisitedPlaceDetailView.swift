import SwiftUI
import MapKit
import CoreLocation

struct VisitedPlaceDetailView: View {
    let record: CheckInRecord
    @EnvironmentObject var historyStore: CheckInHistoryStore

    @State private var isEditing = false
    @State private var editedDate: Date
    @State private var currentDate: Date
    @State private var mapPosition: MapCameraPosition

    init(record: CheckInRecord) {
        self.record = record
        let region = MKCoordinateRegion(
            center: record.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        _mapPosition = State(initialValue: .region(region))
        _editedDate = State(initialValue: record.createdAt)
        _currentDate = State(initialValue: record.createdAt)
    }

    var body: some View {
        Form {
            Section {
                Map(position: $mapPosition) {
                    Marker(record.name, coordinate: record.coordinate)
                        .tint(.red)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section("Place") {
                LabeledContent("Name") {
                    Text(record.name)
                        .multilineTextAlignment(.trailing)
                }

                LabeledContent("Address") {
                    Text(addressText)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(record.address.isEmpty ? .secondary : .primary)
                }

                LabeledContent("Category") {
                    Text(categoryText)
                        .foregroundColor(record.category == nil ? .secondary : .primary)
                }
            }

            Section("Location") {
                LabeledContent("Coordinates") {
                    Text(coordinateText)
                        .monospaced()
                }
            }

            Section("Check-In") {
                if isEditing {
                    DatePicker(
                        "Date & Time",
                        selection: $editedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } else {
                    LabeledContent("Date & Time") {
                        Text(formattedDateTime)
                    }
                }
            }
        }
        .navigationTitle(record.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        cancelEdit()
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveEdit()
                    } else {
                        editedDate = currentDate
                        isEditing = true
                    }
                }
                .disabled(isEditing && editedDate == currentDate)
            }
        }
    }

    private var addressText: String {
        record.address.isEmpty ? "Not available" : record.address
    }

    private var categoryText: String {
        record.category ?? "Uncategorized"
    }

    private var coordinateText: String {
        String(format: "%.6f, %.6f", record.latitude, record.longitude)
    }

    private var formattedDateTime: String {
        "\(Self.dateFormatter.string(from: currentDate)) @ \(Self.timeFormatter.string(from: currentDate))"
    }

    private func saveEdit() {
        let updatedRecord = CheckInRecord(
            id: record.id,
            name: record.name,
            address: record.address,
            latitude: record.latitude,
            longitude: record.longitude,
            category: record.category,
            createdAt: editedDate
        )
        historyStore.update(updatedRecord)
        currentDate = editedDate
        isEditing = false
    }

    private func cancelEdit() {
        editedDate = currentDate
        isEditing = false
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

#Preview {
    let record = CheckInRecord(
        name: "Sample Cafe",
        address: "123 Market St",
        latitude: 37.8012,
        longitude: -122.2727,
        category: "Cafe"
    )
    return NavigationStack {
        VisitedPlaceDetailView(record: record)
            .environmentObject(CheckInHistoryStore())
    }
}
