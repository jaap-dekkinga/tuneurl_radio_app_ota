import SwiftUI
import WebKit

/// Shows an engagement web page inside the app.
///
/// The page comes from the match server, so the view stays on https pages:
/// it loads only https URLs (see SafeLinks), and blocks navigation to any
/// other scheme, such as `javascript:`, `file:`, `tel:` or another app's URL
/// scheme. Pages cannot open new windows or pop-ups.
struct AppWebView: UIViewRepresentable {

    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView  {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        if let safeURL = SafeLinks.webURL(url) {
            view.load(URLRequest(url: safeURL))
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: AppWebView

        init(_ parent: AppWebView) {
            self.parent = parent
        }

        @MainActor
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            let target = navigationAction.request.url
            // about:blank and about:srcdoc are used by pages for empty frames.
            if target?.scheme?.lowercased() == "about" {
                return .allow
            }
            return SafeLinks.isAllowedInWebView(target) ? .allow : .cancel
        }
    }
}
