import Foundation

/// Checks links and phone numbers that come from outside the app (the match
/// server, the ad server) before the app opens, loads or dials them.
///
/// Same rules as `SafeLinks.kt` in the Android app:
/// - Web links must be `https` with a host. `http` is upgraded to `https`.
///   Anything else (`javascript:`, `file:`, `tel:`, other apps' URL schemes)
///   is refused.
/// - Phone numbers may contain only digits, a leading `+`, spaces and `()./-`,
///   with at least 3 digits.
enum SafeLinks {

    /// An https URL with a host, or nil.
    static func webURL(_ raw: String?) -> URL? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return nil }
        let candidate: String
        if trimmed.lowercased().hasPrefix("http://") {
            candidate = "https://" + trimmed.dropFirst("http://".count)
        } else {
            candidate = trimmed
        }
        // encodingInvalidCharacters: false keeps parsing strict: a string with
        // spaces or other characters a browser would guess at is refused.
        guard
            let url = URL(string: candidate, encodingInvalidCharacters: false),
            url.scheme?.lowercased() == "https",
            let host = url.host(), !host.isEmpty
        else { return nil }
        return url
    }

    /// The same check for a URL that already exists (web view navigation, ads).
    static func webURL(_ url: URL?) -> URL? {
        webURL(url?.absoluteString)
    }

    /// True when the in-app web view may load `url`.
    static func isAllowedInWebView(_ url: URL?) -> Bool {
        guard let url else { return false }
        return url.scheme?.lowercased() == "https" && webURL(url) != nil
    }

    private static let phoneAllowed = try! NSRegularExpression(pattern: #"^\+?[0-9 ()./-]{3,32}$"#)

    /// A phone number with only digits, a leading +, spaces and ()./- , or nil.
    static func phoneNumber(_ raw: String?) -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        guard phoneAllowed.firstMatch(in: trimmed, range: range) != nil else { return nil }
        guard trimmed.filter(\.isNumber).count >= 3 else { return nil }
        return trimmed
    }

    /// A `tel:` URL for a checked number, or nil. The system asks the user
    /// before it places the call.
    static func telURL(_ raw: String?) -> URL? {
        dialString(raw).flatMap { URL(string: "tel:" + $0) }
    }

    /// An `sms:` URL for a checked number, or nil.
    static func smsURL(_ raw: String?) -> URL? {
        dialString(raw).flatMap { URL(string: "sms:" + $0) }
    }

    /// The checked number reduced to a leading + and digits, for URLs and
    /// message recipients.
    static func dialString(_ raw: String?) -> String? {
        guard let number = phoneNumber(raw) else { return nil }
        let digits = number.filter { $0.isASCII && $0.isNumber }
        return number.hasPrefix("+") ? "+" + digits : digits
    }
}
