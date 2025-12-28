import SwiftUI

struct VisitedPlacesView: View {
    var body: some View {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    VisitedPlacesView()
}
