import SwiftUI
import MessageUI

struct SMSComposerView: UIViewControllerRepresentable {
    
    @Environment(\.dismiss) var dismiss
    
    let engagement: Engagement
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator

        if let info = engagement.info, !info.isEmpty {
            controller.recipients = [info]
        }
        if MFMessageComposeViewController.canSendText() {
            controller.body = engagement.description
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: SMSComposerView
        init(_ parent: SMSComposerView) {
            self.parent = parent
        }
        
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            DispatchQueue.main.async {
                self.parent.dismiss()
            }
        }
    }
}
