import Foundation

@MainActor
class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var searchText = ""
    @Published var selectedCategory = ""
    @Published var currentPage = 0
    @Published var hasMorePages = true
    
    private let apiService: APIService
    private let pageSize = 10
    
    init(apiService: APIService = .shared) {
        self.apiService = apiService
    }
    
    func fetchProducts(reset: Bool = false) async {
        if reset {
            currentPage = 0
            products = []
        }
        
        isLoading = true
        error = nil
        
        do {
            let response: ProductsResponse
            
            if !searchText.isEmpty {
                response = try await apiService.searchProducts(
                    query: searchText,
                    page: currentPage,
                    size: pageSize
                )
            } else if !selectedCategory.isEmpty {
                response = try await apiService.getProductsByCategory(
                    category: selectedCategory,
                    page: currentPage,
                    size: pageSize
                )
            } else {
                response = try await apiService.fetchProducts(
                    page: currentPage,
                    size: pageSize
                )
            }
            
            if reset {
                products = response.content
            } else {
                products.append(contentsOf: response.content)
            }
            
            hasMorePages = currentPage < response.totalPages - 1
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func loadMore() async {
        if hasMorePages && !isLoading {
            currentPage += 1
            await fetchProducts()
        }
    }
    
    func search(query: String) async {
        searchText = query
        await fetchProducts(reset: true)
    }
    
    func filterByCategory(_ category: String) async {
        selectedCategory = category
        await fetchProducts(reset: true)
    }
    
    func clearFilters() async {
        searchText = ""
        selectedCategory = ""
        await fetchProducts(reset: true)
    }
}
