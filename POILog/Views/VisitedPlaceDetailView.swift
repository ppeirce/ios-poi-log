import SwiftUI
import MapKit
import CoreLocation
import SwiftData

struct VisitedLogEntryView: View {
    let record: CheckIn
    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var editedDate: Date
    @State private var currentDate: Date
    @State private var mapPosition: MapCameraPosition

    init(record: CheckIn) {
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
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("📍 \(record.name)")
                        .font(.headline)
                        .lineLimit(2)

                    Text(addressText)
                        .font(.subheadline)
                        .foregroundColor(record.address.isEmpty ? .secondary : .gray)

                    Text(categoryText)
                        .font(.caption)
                        .foregroundColor(record.category == nil ? .secondary : .orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 12) {
                        if isEditing {
                            DatePicker(
                                "Check-In",
                                selection: $editedDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .font(.caption)
                        } else {
                            detailRow(label: "Check-In", value: formattedDateTime)
                        }

                        detailRow(label: "Coordinates", value: coordinateText, monospaced: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Map(position: $mapPosition) {
                    Marker(record.name, coordinate: record.coordinate)
                        .tint(.red)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                ShareLink(
                    item: captureData.yamlString,
                    subject: Text(record.name),
                    message: Text(shareMessage)
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

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Visited Entry")
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

    private var shareMessage: String {
        record.address.isEmpty ? "Location log entry" : "Location: \(record.address)"
    }

    private var captureData: CaptureData {
        CaptureData(
            date: Self.dateFormatter.string(from: currentDate),
            time: Self.timeFormatter.string(from: currentDate),
            name: record.name,
            address: record.address,
            latitude: record.latitude,
            longitude: record.longitude
        )
    }

    @ViewBuilder
    private func detailRow(label: String, value: String, monospaced: Bool = false) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(monospaced ? .system(.caption, design: .monospaced) : .caption)
                .multilineTextAlignment(.trailing)
        }
    }

    private func saveEdit() {
        record.createdAt = editedDate
        do {
            try modelContext.save()
            currentDate = editedDate
        } catch {
            record.createdAt = currentDate
            editedDate = currentDate
            print("Save failed: \(error)")
        }
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: CheckIn.self, configurations: config)
    let record = CheckIn(
        name: "Sample Cafe",
        address: "123 Market St",
        latitude: 37.8012,
        longitude: -122.2727,
        category: "Cafe"
    )
    container.mainContext.insert(record)
    return NavigationStack {
        VisitedLogEntryView(record: record)
    }
    .modelContainer(container)
}
