import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                     [UIApplication.LaunchOptionsKey : Any]? = nil)
    -> Bool { return true }
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowApplication {
            configuration.delegateClass = SceneDelegate.self
        }
        return configuration
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    var secondaryWindow: UIWindow?
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            setupSecondaryOverlayWindow(in: windowScene)
        }
    }
    
    func setupSecondaryOverlayWindow(in scene: UIWindowScene) {
        let secondaryViewController = UIHostingController(
            rootView:
                EmptyView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(EngagementSheetModifier())
        )
        secondaryViewController.view.backgroundColor = .clear
        let secondaryWindow = PassThroughWindow(windowScene: scene)
        secondaryWindow.rootViewController = secondaryViewController
        secondaryWindow.isHidden = false
        self.secondaryWindow = secondaryWindow
    }
}
