import Foundation

struct Review: Identifiable, Codable {
    let id: Int
    let reviewerName: String
    let comment: String
    let rating: Int
    let helpfulCount: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, reviewerName, comment, rating
        case helpfulCount
        case createdAt
    }
    
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: createdAt) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            return dateFormatter.string(from: date)
        }
        return createdAt
    }
}

struct ReviewsResponse: Codable {
    let content: [Review]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let pageSize: Int
}

struct CreateReviewRequest: Codable {
    let reviewerName: String
    let comment: String
    let rating: Int
    
    enum CodingKeys: String, CodingKey {
        case reviewerName
        case comment
        case rating
    }
}
