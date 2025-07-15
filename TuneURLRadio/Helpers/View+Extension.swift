import SwiftUI

extension View {
    
    func debug() -> some View {
        self.border(Color.random(), width: 1)
    }
}

extension Color {
    
    static func random() -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
