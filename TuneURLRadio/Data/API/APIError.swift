import Foundation

enum APIError: LocalizedError {
        case invalidResponse
        case httpError(statusCode: Int, message: String?)
        case transport(URLError)
        case decoding(Error)
        case encoding(Error)
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "We couldn't understand the server's response. Please try again."
            case .httpError(let statusCode, let message):
                if let message, !message.isEmpty { return message }
                switch statusCode {
                case 400: return "Your request couldn't be processed. Please check and try again."
                case 401: return "You're not authorized. Please sign in and try again."
                case 403: return "You don't have permission to do that."
                case 404: return "We couldn't find what you're looking for."
                case 408: return "The request timed out. Please try again."
                case 429: return "You're doing that too often. Please slow down and try again."
                case 500...599: return "The server had a problem. Please try again later."
                default: return "Something went wrong (code \(statusCode)). Please try again."
                }
            case .transport(let urlError):
                switch urlError.code {
                case .notConnectedToInternet: return "You're offline. Check your connection and try again."
                case .timedOut: return "The request timed out. Please try again."
                case .cannotFindHost, .cannotConnectToHost: return "Can't reach the server. Please try again later."
                case .networkConnectionLost: return "Your connection was lost. Please try again."
                default: return "A network error occurred. Please try again."
                }
            case .decoding:
                return "We couldn't read the server's response. Please try again."
            case .encoding:
                return "We couldn't send your request. Please try again."
            case .unknown:
                return "An unexpected error occurred. Please try again."
            }
        }
    }
