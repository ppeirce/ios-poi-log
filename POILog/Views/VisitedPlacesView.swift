import SwiftUI
import CoreLocation
import MapKit
import SwiftData

struct VisitedPlacesView: View {
    @ObservedObject var locationManager: LocationManager
    @Query(sort: \CheckIn.createdAt, order: .reverse)
    private var checkIns: [CheckIn]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var dateFilter: DateFilter = .all

    var body: some View {
        Group {
            if checkIns.isEmpty {
                emptyState
                    .padding()
            } else if filteredRecords.isEmpty {
                noMatchesState
                    .padding()
            } else {
                listContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Visited")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Date Range", selection: $dateFilter) {
                        ForEach(DateFilter.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }

                Menu {
                    ShareLink(
                        item: ExportService.exportJSONFile(filteredRecords),
                        preview: SharePreview("POI Log", image: Image(systemName: "doc.plaintext"))
                    ) {
                        Label("Export JSON", systemImage: "doc.text")
                    }

                    ShareLink(
                        item: ExportService.exportCSVFile(filteredRecords),
                        preview: SharePreview("POI Log", image: Image(systemName: "tablecells"))
                    ) {
                        Label("Export CSV", systemImage: "tablecells")
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(filteredRecords.isEmpty)
            }
        }
        .searchable(text: $searchText, prompt: "Search places")
    }

    private var listContent: some View {
        List {
            if let mapRegion {
                Map(position: .constant(.region(mapRegion)), interactionModes: []) {
                    ForEach(mapRecords, id: \.id) { record in
                        Marker(record.name, coordinate: record.coordinate)
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
            }

            ForEach(filteredRecords, id: \.id) { record in
                NavigationLink {
                    VisitedLogEntryView(record: record)
                } label: {
                    HistoryRowView(record: record, currentLocation: locationManager.currentLocation)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            Text("Visited Places")
                .font(.headline)

            Text("History will appear here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var noMatchesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            Text("No matches")
                .font(.headline)

            Text("Try adjusting your search or date filter.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var filteredRecords: [CheckIn] {
        var records = checkIns
        if !searchText.isEmpty {
            let needle = searchText.lowercased()
            records = records.filter {
                $0.name.lowercased().contains(needle) ||
                $0.address.lowercased().contains(needle)
            }
        }

        if let cutoff = dateFilter.cutoffDate {
            records = records.filter { $0.createdAt >= cutoff }
        }

        return records
    }

    private var mapRecords: [CheckIn] {
        Array(filteredRecords.prefix(60))
    }

    private var mapRegion: MKCoordinateRegion? {
        guard let first = filteredRecords.first else { return nil }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for record in filteredRecords.dropFirst() {
            minLat = min(minLat, record.latitude)
            maxLat = max(maxLat, record.latitude)
            minLon = min(minLon, record.longitude)
            maxLon = max(maxLon, record.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let latDelta = max((maxLat - minLat) * 1.4, 0.01)
        let lonDelta = max((maxLon - minLon) * 1.4, 0.01)
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    private enum DateFilter: String, CaseIterable, Identifiable {
        case all
        case last7
        case last30

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all: return "All time"
            case .last7: return "Last 7 days"
            case .last30: return "Last 30 days"
            }
        }

        var cutoffDate: Date? {
            switch self {
            case .all:
                return nil
            case .last7:
                return Calendar.current.date(byAdding: .day, value: -7, to: Date())
            case .last30:
                return Calendar.current.date(byAdding: .day, value: -30, to: Date())
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            let record = filteredRecords[index]
            modelContext.delete(record)
        }
        do {
            try modelContext.save()
        } catch {
            print("Delete failed: \(error)")
        }
    }
}

private struct HistoryRowView: View {
    let record: CheckIn
    let currentLocation: CLLocationCoordinate2D?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(record.name)
                    .font(.headline)
                    .lineLimit(2)

                if !record.address.isEmpty {
                    Text(record.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let distanceText {
                        Label(distanceText, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            if let category = record.category {
                Text(category)
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.14))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }

    private var formattedDate: String {
        "\(Self.dateFormatter.string(from: record.createdAt)) @ \(Self.timeFormatter.string(from: record.createdAt))"
    }

    private var distanceText: String? {
        guard let currentLocation else { return nil }
        let current = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let target = CLLocation(latitude: record.latitude, longitude: record.longitude)
        let distance = current.distance(from: target)
        let miles = distance / 1609.34
        if miles < 0.01 {
            return String(format: "%.0f ft", distance * 3.28084)
        }
        return String(format: "%.2f mi", miles)
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
    let container = try! ModelContainer(for: CheckIn.self, configurations: config)
    let record = CheckIn(
        name: "Sample Cafe",
        address: "123 Market St",
        latitude: 37.8012,
        longitude: -122.2727,
        category: "Cafe"
    )
    container.mainContext.insert(record)
    return VisitedPlacesView(locationManager: LocationManager())
        .modelContainer(container)
}
