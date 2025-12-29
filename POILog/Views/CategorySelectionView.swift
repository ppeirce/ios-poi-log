import SwiftUI
import MapKit

struct CategorySelectionView: View {
    @ObservedObject var searchManager: POISearchManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose which POI categories should appear in search.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                FlowLayout(spacing: 10) {
                    ForEach(sortedCategories, id: \.rawValue) { category in
                        CategoryChip(
                            title: category.displayName,
                            isSelected: searchManager.selectedCategories.contains(category)
                        ) {
                            toggle(category)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedCategories: [MKPointOfInterestCategory] {
        POISearchManager.availableCategories.sorted { $0.displayName < $1.displayName }
    }

    private func toggle(_ category: MKPointOfInterestCategory) {
        if searchManager.selectedCategories.contains(category) {
            searchManager.selectedCategories.remove(category)
        } else {
            searchManager.selectedCategories.insert(category)
        }
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var backgroundColor: Color {
        isSelected ? Color.orange.opacity(0.85) : Color(.systemGray5)
    }

    private var foregroundColor: Color {
        isSelected ? .white : .primary
    }

    private var borderColor: Color {
        isSelected ? Color.orange : Color(.systemGray3)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                maxRowWidth = max(maxRowWidth, rowWidth)
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth += (rowWidth > 0 ? spacing : 0) + size.width
                rowHeight = max(rowHeight, size.height)
            }
        }

        if rowWidth > 0 {
            totalHeight += rowHeight
            maxRowWidth = max(maxRowWidth, rowWidth)
        }

        let finalWidth = maxWidth.isInfinite ? maxRowWidth : maxWidth
        return CGSize(width: finalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        let maxX = bounds.maxX

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    CategorySelectionView(searchManager: POISearchManager())
}
