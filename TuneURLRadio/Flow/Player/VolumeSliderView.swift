import SwiftUI
import AVKit
import MediaPlayer

struct VolumeSliderView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        let view = MPVolumeView()
        view.tintColor = UIColor.white
        
        let states = [UIControl.State.normal, .selected, .highlighted, .disabled, .focused, .reserved, .application]
        for state in states {
            view.setVolumeThumbImage(sfSymbolToUIImage("circle.fill", pointSize: 12), for: state)
            
            view.setMinimumVolumeSliderImage(
                trackImage(color: .white, state: state),
                for: state
            )
            view.setMaximumVolumeSliderImage(
                trackImage(color: .white.withAlphaComponent(0.5), state: state),
                for: state
            )
        }
        
        if let slider = view.subviews.first(where: { $0 is UISlider }) as? UISlider {
            slider.minimumValueImage = sfSymbolToUIImage("speaker.fill", pointSize: 16, color: .white.withAlphaComponent(0.5))
            slider.maximumValueImage = sfSymbolToUIImage("speaker.wave.3.fill", pointSize: 16, color: .white.withAlphaComponent(0.5))
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

private func sfSymbolToUIImage(
    _ name: String,
    pointSize: CGFloat = 20,
    color: UIColor = .white,
    weight: UIImage.SymbolWeight = .regular
) -> UIImage? {
    let config = UIImage.SymbolConfiguration(
        pointSize: pointSize,
        weight: weight
    )
    return UIImage(
        systemName: name,
        withConfiguration: config
    )?.withTintColor(color).withRenderingMode(.alwaysOriginal)
}

private func image(with color: UIColor, size: Double, cornerRadius: CGFloat = 0) -> UIImage {
    let size = CGSize(width: 20, height: size)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        color.setFill()
        path.fill()
    }
}

private func trackImage(
    color: UIColor,
    state: UIControl.State
) -> UIImage {
    let image = image(with: color, size: 4, cornerRadius: 2)
    return image
        .withRenderingMode(.alwaysOriginal)
        .resizableImage(
            withCapInsets: .init(top: 0, left: 6, bottom: 0, right: 6),
            resizingMode: .tile
        )
}
