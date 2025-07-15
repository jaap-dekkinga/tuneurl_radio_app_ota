import SwiftUI

struct PlayerStatusLineView: View {
    
    let state: StateManager.PlayerState
    
    var body: some View {
        ZStack {
            HStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.4),
                        .white.opacity(0.2),
                        .white.opacity(0.1),
                        .white.opacity(0.05),
                        .clear,
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 5)
                
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        .white.opacity(0.05),
                        .white.opacity(0.1),
                        .white.opacity(0.2),
                        .white.opacity(0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 5)
            }
            .clipShape(Capsule())
            
            Text(state.title)
                .font(.caption.weight(.bold))
                .fontDesign(.rounded)
                .padding(.horizontal, 8)
                .transition(.opacity)
                .animation(.linear(duration: 0.3), value: state)
        }
    }
}
