import Foundation

class APIService {
    static let shared = APIService()
    
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String = "http://localhost:8080") {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Product Methods
    
    func fetchProducts(page: Int = 0, size: Int = 10, category: String? = nil, search: String? = nil) async throws -> ProductsResponse {
        var components = URLComponents(string: "\(baseURL)/api/products")
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
    
    func fetchProductDetail(id: Int) async throws -> Product {
        let url = URL(string: "\(baseURL)/api/products/\(id)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(Product.self, from: data)
    }
    
    // MARK: - Review Methods
    
    func fetchProductReviews(productId: Int, page: Int = 0, size: Int = 10) async throws -> ReviewsResponse {
        let url = URL(string: "\(baseURL)/api/products/\(productId)/reviews?page=\(page)&size=\(size)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(ReviewsResponse.self, from: data)
    }
    
    func addReview(productId: Int, reviewerName: String, comment: String, rating: Int) async throws -> Review {
        let url = URL(string: "\(baseURL)/api/products/\(productId)/reviews")!
        
        let request = CreateReviewRequest(
            reviewerName: reviewerName,
            comment: comment,
            rating: rating
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...201).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(Review.self, from: data)
    }
    
    // MARK: - Search Methods
    
    func searchProducts(query: String, page: Int = 0, size: Int = 10) async throws -> ProductsResponse {
        try await fetchProducts(page: page, size: size, search: query)
    }
    
    func getProductsByCategory(category: String, page: Int = 0, size: Int = 10) async throws -> ProductsResponse {
        try await fetchProducts(page: page, size: size, category: category)
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL geçersiz"
        case .invalidResponse:
            return "Sunucudan geçersiz yanıt alındı"
        case .decodingError:
            return "Veri çözümleme hatası"
        case .networkError(let error):
            return "Ağ hatası: \(error.localizedDescription)"
        case .unknown:
            return "Bilinmeyen hata oluştu"
        }
    }
}
