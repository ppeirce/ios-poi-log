import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gearshape")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            Text("Settings")
                .font(.headline)

            Text("Search radius and filters will live here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    SettingsView()
}
