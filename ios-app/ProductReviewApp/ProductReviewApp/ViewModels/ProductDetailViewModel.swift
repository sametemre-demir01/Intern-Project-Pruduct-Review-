import Foundation
import Combine

@MainActor
class ProductDetailViewModel: ObservableObject {
    @Published var product: Product?
    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var isLoadingReviews = false
    @Published var error: String?
    @Published var currentPage = 0
    @Published var hasMoreReviews = true
    
    private let apiService = APIService.shared
    private let pageSize = 10
    
    func loadProduct(id: Int) async {
        isLoading = true
        error = nil
        
        do {
            product = try await apiService.fetchProductDetail(id: id)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadReviews(productId: Int, reset: Bool = false) async {
        if reset {
            currentPage = 0
            hasMoreReviews = true
            reviews = []
        }
        
        guard !isLoadingReviews && hasMoreReviews else { return }
        
        isLoadingReviews = true
        
        do {
            let response = try await apiService.fetchReviews(
                productId: productId,
                page: currentPage,
                size: pageSize
            )
            
            if reset {
                reviews = response.content
            } else {
                reviews.append(contentsOf: response.content)
            }
            
            hasMoreReviews = !response.last
            currentPage += 1
            
        } catch {
            print("Yorumlar yüklenemedi: \(error)")
        }
        
        isLoadingReviews = false
    }
    
    func submitReview(productId: Int, userName: String, rating: Int, comment: String) async -> Bool {
        do {
            let newReview = try await apiService.createReview(
                productId: productId,
                userName: userName,
                rating: rating,
                comment: comment
            )
            reviews.insert(newReview, at: 0)
            
            // Reload product to get updated rating
            await loadProduct(id: productId)
            
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }
    
    func loadMoreReviews(productId: Int) async {
        await loadReviews(productId: productId, reset: false)
    }
}
