import SwiftUI

struct ProductComparisonView: View {
    @ObservedObject var viewModel: ProductListViewModel
    @State private var comparedProducts: [Product] = []
    @State private var analysis: String = ""
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ürün Karşılaştırma")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                if isLoading {
                    ProgressView("Karşılaştırma yapılıyor...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("Tekrar Dene") {
                            Task {
                                await loadComparison()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // Products Comparison
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(comparedProducts) { product in
                                ProductComparisonCard(product: product)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // AI Analysis
                    if !analysis.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("AI Analizi")
                                    .font(.headline)
                            }
                            
                            Text(analysis)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadComparison()
        }
    }
    
    private func loadComparison() async {
        isLoading = true
        error = nil
        
        do {
            let result = try await viewModel.compareSelectedProducts()
            comparedProducts = result.products
            analysis = result.analysis
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct ProductComparisonCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 150)
            .cornerRadius(8)
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(product.category)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", product.averageRating))
                            .font(.caption)
                        Text("(\(product.reviewCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "₺%.2f", product.price))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(width: 250)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        ProductComparisonView(viewModel: ProductListViewModel())
    }
}