import Foundation

@MainActor
class ProductDetailViewModel: ObservableObject {
    @Published var product: Product? = nil
    @Published var reviews: [Review] = []
    @Published var isLoadingProduct = false
    @Published var isLoadingReviews = false
    @Published var error: String? = nil
    @Published var currentReviewPage = 0
    @Published var hasMoreReviews = true
    
    @Published var reviewerName = ""
    @Published var reviewComment = ""
    @Published var selectedRating = 5
    @Published var isSubmittingReview = false
    
    private let apiService: APIService
    private let reviewPageSize = 5
    private let productId: Int
    
    init(productId: Int, apiService: APIService = .shared) {
        self.productId = productId
        self.apiService = apiService
    }
    
    func fetchProductDetail() async {
        isLoadingProduct = true
        error = nil
        
        do {
            product = try await apiService.fetchProductDetail(id: productId)
            isLoadingProduct = false
        } catch {
            self.error = error.localizedDescription
            isLoadingProduct = false
        }
    }
    
    func fetchReviews(reset: Bool = false) async {
        if reset {
            currentReviewPage = 0
            reviews = []
        }
        
        isLoadingReviews = true
        error = nil
        
        do {
            let response = try await apiService.fetchProductReviews(
                productId: productId,
                page: currentReviewPage,
                size: reviewPageSize
            )
            
            if reset {
                reviews = response.content
            } else {
                reviews.append(contentsOf: response.content)
            }
            
            hasMoreReviews = currentReviewPage < response.totalPages - 1
            isLoadingReviews = false
        } catch {
            self.error = error.localizedDescription
            isLoadingReviews = false
        }
    }
    
    func loadMoreReviews() async {
        if hasMoreReviews && !isLoadingReviews {
            currentReviewPage += 1
            await fetchReviews()
        }
    }
    
    func submitReview() async {
        guard !reviewerName.isEmpty && !reviewComment.isEmpty else {
            error = "Lütfen tüm alanları doldurunuz"
            return
        }
        
        guard selectedRating >= 1 && selectedRating <= 5 else {
            error = "Puanı 1-5 arasında seçiniz"
            return
        }
        
        isSubmittingReview = true
        error = nil
        
        do {
            let newReview = try await apiService.addReview(
                productId: productId,
                reviewerName: reviewerName,
                comment: reviewComment,
                rating: selectedRating
            )
            
            reviews.insert(newReview, at: 0)
            reviewerName = ""
            reviewComment = ""
            selectedRating = 5
            isSubmittingReview = false
        } catch {
            self.error = error.localizedDescription
            isSubmittingReview = false
        }
    }
    
    func clearReviewForm() {
        reviewerName = ""
        reviewComment = ""
        selectedRating = 5
        error = nil
    }
}
