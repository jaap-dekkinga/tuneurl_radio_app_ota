import Foundation

class API {
    let baseURL: URL
    let session: URLSession
    let encoder: JSONEncoder
    let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        encoder: JSONEncoder? = nil,
        decoder: JSONDecoder? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        if let encoder {
            self.encoder = encoder
        } else {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            self.encoder = encoder
        }
        if let decoder {
            self.decoder = decoder
        } else {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            self.decoder = decoder
        }
    }

    // Generic GET
    func get<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await dataRequest(request)
    }

    // Generic POST with Encodable body
    func post<Parameters: Encodable, T: Decodable>(
        _ path: String,
        params: Parameters,
        headers: [String: String] = [:]
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        do {
            request.httpBody = try encoder.encode(params)
        } catch {
            throw APIError.encoding(error)
        }
        return try await dataRequest(request)
    }

    // Fire-and-forget POST with no response body
    func post<Parameters: Encodable>(
        _ path: String,
        params: Parameters,
        headers: [String: String] = [:]
    ) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        do {
            request.httpBody = try encoder.encode(params)
        } catch {
            throw APIError.encoding(error)
        }
        _ = try await rawDataRequest(request)
    }
    
    // MARK: - Internal request helpers
    private func dataRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, _) = try await rawDataRequest(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    @discardableResult
    private func rawDataRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, resp) = try await session.data(for: request)
            guard let http = resp as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            guard (200..<300).contains(http.statusCode) else {
                // Try to decode a server-provided error message
                let message: String?
                if !data.isEmpty, let decoded = try? decoder.decode(APIErrorBody.self, from: data) {
                    message = decoded.message
                } else if let text = String(data: data, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    message = text
                } else {
                    message = nil
                }
                throw APIError.httpError(statusCode: http.statusCode, message: message)
            }
            return (data, http)
        } catch let urlError as URLError {
            throw APIError.transport(urlError)
        } catch let decoding as DecodingError {
            // This catch will be used by dataRequest when decoding T fails; raw request shouldn't decode T
            throw APIError.decoding(decoding)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unknown
        }
    }
}

private struct APIErrorBody: Decodable {
    let message: String?
}
