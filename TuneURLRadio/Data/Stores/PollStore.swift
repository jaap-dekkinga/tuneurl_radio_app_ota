import Foundation

// TODO: will be refactored when poll feature will be changed
@Observable
class PollStore {
    
    static let shared = PollStore()
    
    private let client: API
    
    private init() {
        let baseURL = URL(string: "https://pollapiwebservice.us-east-2.elasticbeanstalk.com")!
        
        let dateFormatter = DateFormatter()
        let timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS"
        dateFormatter.timeZone = timeZone
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        client = API(
            baseURL: baseURL,
            encoder: encoder,
            decoder: decoder
        )
    }
    
    func saveVote(
        value: Bool,
        pollId: String
    ) async throws -> PollResults? {
        let request = SaveVoteRequest(
            vote: value,
            pollId: pollId,
            voteDate: Date.now
        )
        let response: PollResponse = try await client.post("/api/pollapi", params: request)
        return response.value.first
    }
}

struct SaveVoteRequest: Encodable {
    let vote: String
    let pollId: String
    let voteDate: Date
    
    init(vote: Bool, pollId: String, voteDate: Date) {
        self.vote = vote ? "yes" : "no"
        self.pollId = pollId
        self.voteDate = voteDate
    }
    
    enum CodingKeys: String, CodingKey {
        case vote = "Response"
        case pollId = "Name"
        case voteDate = "ResponseTime"
    }
}

struct PollResults: Decodable {
    let numberOfYes: Int
    let numberOfNo: Int
}

struct PollResponse: Decodable {
    let value: [PollResults]
}
