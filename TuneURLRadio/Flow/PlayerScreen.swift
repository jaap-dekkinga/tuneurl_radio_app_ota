import SwiftUI

struct PlayerScreen: View {
    
    let animation: Namespace.ID
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                /// Drag Indicator Mimick
                Capsule()
                    .fill(.primary.secondary)
                    .frame(width: 35, height: 3)
                
                HStack(spacing: 0) {
                    PlayerInfo(.init(width: 80, height: 80))
                    
                    Spacer(minLength: 0)
                    
                    /// Expanded Actions
                    Group {
                        Button("", systemImage: "star.circle.fill") {
                            
                        }
                        
                        Button("", systemImage: "ellipsis.circle.fill") {
                            
                        }
                    }
                    .font(.title)
                    .foregroundStyle(Color.primary, Color.primary.opacity(0.1))
                }
                .padding(.horizontal, 15)
            }
            .navigationTransition(.zoom(sourceID: AnimationID.playerView.rawValue, in: animation))
        }
        /// To Avoid Transparency!
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
    
    @ViewBuilder
    func PlayerInfo(_ size: CGSize) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: size.height / 4)
                .fill(.blue.gradient)
                .frame(width: size.width, height: size.height)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Some Apple Music Title")
                    .font(.callout)
                
                Text("Some Artist Name")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .lineLimit(1)
        }
    }
}
