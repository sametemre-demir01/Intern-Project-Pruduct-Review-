//Spring Boot API'sine HTTP istekleri göndermek ve yanıtları işlemek için
//  tasarlanmış bir servis sınıf
import Foundation

struct Product: Identifiable, Codable { //ürün bilgileri
    let id: Int
    let name: String
    let description: String
    let price: Double
    let category: String
    let imageUrl: String?
    let averageRating: Double
    let reviewCount: Int
    let aiSummary: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, price, category
        case imageUrl = "imageUrl"
        case averageRating = "averageRating"
        case reviewCount = "reviewCount"
        case aiSummary = "aiSummary"
    }
}

struct ProductsResponse: Codable { //sayfalanmış ürün listesi
    let content: [Product]
    let totalPages: Int
    let totalElements: Int
    let number: Int
    let size: Int
    let first: Bool
    let last: Bool
}

struct Review: Identifiable, Codable { //inceleme verisi
    let id: Int
    let productId: Int
    let userName: String
    let rating: Int
    let comment: String
    let createdAt: String
    let helpfulCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "productId"
        case userName = "userName"
        case rating, comment
        case createdAt = "createdAt"
        case helpfulCount = "helpfulCount"
    }
}

// Fiyat düşüşü modeli
struct PriceDrop: Identifiable, Codable {
    let productId: Int
    let productName: String
    let oldPrice: Double
    let newPrice: Double
    let changePercent: Double
    let changedAt: String
    
    var id: String { "\(productId)-\(changedAt)" }
}

// Bildirim modelleri
enum NotificationType: String, Codable {
    case review = "review"
    case order = "order"
    case system = "system"
    case priceDrop = "price_drop"
}

struct Notification: Identifiable, Codable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let timestamp: Date
    var isRead: Bool
    let productId: String?
    let productName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, body, timestamp, isRead
        case productId = "productId"
        case productName = "productName"
    }
}

struct ReviewsResponse: Codable { //İncelemeler için sayfalanmış yanıt
    let content: [Review]
    let totalPages: Int
    let totalElements: Int
    let number: Int
    let size: Int
    let first: Bool
    let last: Bool
}

struct CreateReviewRequest: Codable { //Yeni inceleme göndermek için istek gövdesi.
    let productId: Int
    let userName: String
    let rating: Int
    let comment: String
}

struct ProductComparisonRequest: Codable { //Ürün karşılaştırma için istek
    let productIds: [Int]
}

struct ProductComparisonResponse: Codable { //Ürün karşılaştırma yanıtı
    let products: [Product]
    let analysis: String
}

public class APIService { // singleton, uygulama boyunca tek nesne kullanılır
    static let shared = APIService()
    
    private static let baseURL: String = "http://localhost:8080"
    private let session: URLSession
    
    //baseURL parametresi alır. URLSession yapılandırılır.
    init() { //varsayılan baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Product Methods
    //Ürünleri getirir
    func fetchProducts(page: Int = 0, size: Int = 10, category: String? = nil, search: String? = nil) async throws -> ProductsResponse {
        var components = URLComponents(string: "\(APIService.baseURL)/api/products")
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        
        if let category = category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ProductsResponse.self, from: data)
    }
    
    //Tek ürün detayını alır
    func fetchProductDetail(id: Int) async throws -> Product {
        guard let url = URL(string: "\(APIService.baseURL)/api/products/\(id)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(Product.self, from: data)
    }
    //Kategorileri listeler.
    func fetchCategories() async throws -> [String] {
        guard let url = URL(string: "\(APIService.baseURL)/api/products/categories") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([String].self, from: data)
    }
    
    // MARK: - Review Methods
    //Bir ürünün incelemelerini getirir.
    func fetchReviews(productId: Int, page: Int = 0, size: Int = 10) async throws -> ReviewsResponse {
        var components = URLComponents(string: "\(APIService.baseURL)/api/reviews/product/\(productId)")
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ReviewsResponse.self, from: data)
    }
    //Yeni inceleme gönderir.
    func createReview(productId: Int, userName: String, rating: Int, comment: String) async throws -> Review {
        guard let url = URL(string: "\(APIService.baseURL)/api/reviews") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let reviewRequest = CreateReviewRequest(
            productId: productId,
            userName: userName,
            rating: rating,
            comment: comment
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(reviewRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(Review.self, from: data)
    }
    
    // MARK: - Comparison Methods
    
    func compareProducts(ids: [Int]) async throws -> [Product] {
        guard let url = URL(string: "\(APIService.baseURL)/api/products/compare?ids=\(ids.map { String($0) }.joined(separator: ","))") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Product].self, from: data)
    }
    
    func compareWithAI(productIds: [Int]) async throws -> String {
        guard let url = URL(string: "\(APIService.baseURL)/api/ai/compare") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let comparisonRequest = ProductComparisonRequest(productIds: productIds)
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(comparisonRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let responseData = try decoder.decode(ProductComparisonResponse.self, from: data)
        return responseData.analysis
    }
    
    // Fiyat düşüşü bildirimlerini getir
    static func getPriceDrops() async throws -> [PriceDrop] {
        guard let url = URL(string: "\(APIService.baseURL)/api/price-alerts/drops") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([PriceDrop].self, from: data)
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Sunucu hatası"
        case .decodingError:
            return "Veri işleme hatası"
        }
    }
}
