import SwiftUI

struct EngagementActionButton: View {
    let title: LocalizedStringKey
    let color: Color
    let action: () -> Void
    
    init(
        _ title: LocalizedStringKey,
        color: Color,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
