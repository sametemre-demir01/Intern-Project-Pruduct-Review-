import Foundation

struct Product: Identifiable, Codable {
    let id: Int
    let name: String
    let description: String
    let category: String
    let price: Double
    let imageUrl: String?
    let averageRating: Double
    let reviewCount: Int
    let ratingBreakdown: [String: Int]?
    let aiSummary: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, price
        case imageUrl
        case averageRating
        case reviewCount
        case ratingBreakdown
        case aiSummary
    }
}

struct ProductsResponse: Codable {
    let content: [Product]
    let totalElements: Int
    let totalPages: Int
    let currentPage: Int
    let pageSize: Int
}
