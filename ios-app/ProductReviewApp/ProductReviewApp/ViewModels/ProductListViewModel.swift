import Foundation
import Combine

//ürün listesi ekranı için ViewModel katmanı:ürünlerin listelenmesi, filtrelenmesi,
// aranması ve sayfalanması

@MainActor
class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = [] //Ürün listesi. Dinamik olarak yüklenir ve eklenir
    @Published var categories: [String] = [] //mevcut kategoriler, filtreleme için
    @Published var selectedCategory: String = ""
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentPage = 0
    @Published var hasMorePages = true
    @Published var selectedProducts: Set<Int> = [] //Çoklu seçim için seçili ürün ID'leri
    @Published var isSelectionMode = false //Çoklu seçim modu aktif mi?
    @Published var gridMode: Int = 2 // Grid modu: 1, 2, veya 4 sütun
    
    private let apiService = APIService.shared
    private let pageSize = 10
    
    func loadProducts(reset: Bool = false) async {
        if reset {
            currentPage = 0
            hasMorePages = true
            products = []
        }
        
        guard !isLoading && hasMorePages else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await apiService.fetchProducts(
                page: currentPage,
                size: pageSize,
                category: selectedCategory.isEmpty ? nil : selectedCategory,
                search: searchText.isEmpty ? nil : searchText
            )
            
            if reset {
                products = response.content
            } else {
                products.append(contentsOf: response.content)
            }
            
            hasMorePages = !response.last
            currentPage += 1
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadCategories() async {
        do {
            categories = try await apiService.fetchCategories()
        } catch {
            print("Kategoriler yüklenemedi: \(error)")
        }
    }
    
    func search() async {
        await loadProducts(reset: true)
    }
    
    func filterByCategory(_ category: String) async {
        selectedCategory = category
        await loadProducts(reset: true)
    }
    
    func loadMore() async {
        await loadProducts(reset: false)
    }
    
    // Çoklu seçim metodları
    func toggleSelection(for productId: Int) {
        if selectedProducts.contains(productId) {
            selectedProducts.remove(productId)
        } else {
            selectedProducts.insert(productId)
        }
    }
    
    func clearSelection() {
        selectedProducts.removeAll()
        isSelectionMode = false
    }
    
    func startSelectionMode() {
        isSelectionMode = true
    }
    
    func toggleGridMode() {
        if gridMode == 1 {
            gridMode = 2
        } else if gridMode == 2 {
            gridMode = 4
        } else {
            gridMode = 1
        }
    }
    
    func compareSelectedProducts() async throws -> (products: [Product], analysis: String) {
        guard selectedProducts.count >= 2 else {
            throw NSError(domain: "ProductComparison", code: 1, userInfo: [NSLocalizedDescriptionKey: "En az 2 ürün seçmelisiniz"])
        }
        
        let productIds = Array(selectedProducts)
        let products = try await apiService.compareProducts(ids: productIds)
        let analysis = try await apiService.compareWithAI(productIds: productIds)
        
        return (products, analysis)
    }
}
