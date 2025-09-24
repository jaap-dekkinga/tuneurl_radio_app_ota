import UIKit
import SwiftUI
import Pulse
import PulseProxy
import PulseUI

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        setupLogging()
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowApplication {
            configuration.delegateClass = SceneDelegate.self
        }
        return configuration
    }
    
    // MARK: - Helpers
    func setupLogging() {
        NetworkLogger.enableProxy()
        LoggerStore.shared.removeAll()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(presentDebugging),
            name: UIDevice.deviceDidShakeNotification,
            object: nil
        )
    }
    
    @objc private func presentDebugging() {
        let view = NavigationView {
            ConsoleView(
                mode: .logs
            )
        }
        UIViewController.currentViewController()?.present(UIHostingController(rootView: view), animated: true)
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
                .modifier(GlobalSheetModifier())
        )
        secondaryViewController.view.backgroundColor = .clear
        let secondaryWindow = PassThroughWindow(windowScene: scene)
        secondaryWindow.rootViewController = secondaryViewController
        secondaryWindow.isHidden = false
        self.secondaryWindow = secondaryWindow
    }
}
