import UIKit

enum ReportAction {
    case heard(Engagement)
    case interested(Engagement)
    case acted(Engagement)
    case shared(Engagement)
    
    func report() {
        ReportingManager.shared.report(self)
    }
}
