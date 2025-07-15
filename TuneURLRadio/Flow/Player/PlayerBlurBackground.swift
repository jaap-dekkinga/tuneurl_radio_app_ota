import SwiftUI

struct PlayerBlurBackground: View {
    
    @State private var animation = false
    
    let displayImage: UIImage?
    let animationDuration: Double
    
    init(
        displayImage: UIImage?,
        animationDuration: Double = AnimationID.PlayerArtworkUpdateDuration
    ) {
        self.displayImage = displayImage
        self.animationDuration = animationDuration
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let displayImage {
                    ZStack {
                        firstImage(displayImage, geometry)
                        image(displayImage, geometry)
                        image(displayImage, geometry)
                        image(displayImage, geometry)
                    }
                    .id(displayImage.hash)
                    .transition(
                        .opacity.animation(.linear(duration: animationDuration))
                    )
                    .transaction { transaction in
                        transaction.addAnimationCompletion {
                            animation.toggle()
                        }
                    }
                } else {
                    Color(uiColor: .darkGray)
                }
                
                VisualEffect(effect: UIBlurEffect(style: .light))
                VisualEffect(effect: UIBlurEffect(style: .light))
                VisualEffect(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            animation.toggle()
        }
    }
    
    func image(_ image: UIImage, _ geometry: GeometryProxy) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(
                width: randomFrame(geometry.size.width),
                height: randomFrame(geometry.size.width)
            )
            .scaleEffect(randomCGFloat(in: 1...2.5))
            .opacity(0.5)
            .rotationEffect(.degrees(randomDouble(in: -360...360)), anchor: .center)
            .offset(x: randomCGFloat(in: -300...300), y: randomCGFloat(in: -300...300))
            .blendMode(.lighten)
            .saturation(randomDouble(in: 0.4...1.4))
            .contrast(2)
            .animation(.linear(duration: 40).repeatForever(), value: animation)
    }
    
    func firstImage(_ image: UIImage, _ geometry: GeometryProxy) -> some View {
        Image(uiImage: image)
            .resizable()
            .brightness(-0.5)
            .rotationEffect(.degrees(randomDouble(in: -360...360)), anchor: .center)
            .frame(width: geometry.size.height*2, height: geometry.size.height*2)
            .animation(.linear(duration: 40).repeatForever(), value: animation)
    }
    
    func randomFrame(_ base: CGFloat) -> CGFloat {
        let randomNumber = CGFloat.random(in: -100...300)
        let frame = base + randomNumber
        return frame
    }
    
    func randomCGFloat(in range: ClosedRange<CGFloat>) -> CGFloat {
        let randomNumber = CGFloat.random(in: range)
        return randomNumber
    }
    
    func randomDouble(in range: ClosedRange<Double>) -> Double {
        let randomNumber = Double.random(in: range)
        return randomNumber
    }
}

struct VisualEffect: UIViewRepresentable {
    var effect: UIVisualEffect?
    let effectView = UIVisualEffectView(effect: nil)
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        effectView.effect = effect
        return effectView
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { }
}

#Preview {
    PlayerBlurBackground(displayImage: UIImage.stationLogo)
}
