import SwiftUI

struct FailedLoadContentView: View {
    
    var body: some View {
        Text("Failder to load content.")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxHeight: .infinity)
    }
}
