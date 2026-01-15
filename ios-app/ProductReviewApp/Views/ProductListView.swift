import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    @State private var showingSearch = false
    @State private var selectedProduct: Product? = nil
    @State private var showingDetail = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Arama ve Filtre
                SearchBarView(
                    text: $viewModel.searchText,
                    onSearch: { query in
                        Task {
                            await viewModel.search(query: query)
                        }
                    }
                )
                
                // Kategoriler
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterButtonView(
                            title: "Tümü",
                            isSelected: viewModel.selectedCategory.isEmpty,
                            action: {
                                Task {
                                    await viewModel.clearFilters()
                                }
                            }
                        )
                        
                        ForEach(["Elektronik", "Kıyafet", "Kitap", "Spor"], id: \.self) { category in
                            FilterButtonView(
                                title: category,
                                isSelected: viewModel.selectedCategory == category,
                                action: {
                                    Task {
                                        await viewModel.filterByCategory(category)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Ürün Listesi
                if viewModel.isLoading && viewModel.products.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.products.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Ürün bulunamadı")
                            .font(.headline)
                        Text("Arama kriterlerinizi değiştirmeyi deneyin")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.products) { product in
                                NavigationLink(value: product) {
                                    ProductCardView(product: product)
                                }
                                .buttonStyle(.plain)
                                
                                if viewModel.products.last?.id == product.id && viewModel.hasMorePages {
                                    ProgressView()
                                        .onAppear {
                                            Task {
                                                await viewModel.loadMore()
                                            }
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                        Spacer()
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
                }
            }
            .navigationTitle("Ürünler")
            .navigationDestination(for: Product.self) { product in
                ProductDetailView(product: product)
            }
            .task {
                await viewModel.fetchProducts()
            }
        }
    }
}

struct FilterButtonView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(16)
        }
    }
}

struct ProductCardView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ürün Resmi
            if let imageUrl = product.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 150)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                HStack {
                    // Fiyat
                    Text(String(format: "₺%.2f", product.price))
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    // Yıldız Puanı
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", product.averageRating))
                            .font(.caption)
                        Text("(\(product.reviewCount))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SearchBarView: View {
    @Binding var text: String
    let onSearch: (String) -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Ürün ara...", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onSearch(text)
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    onSearch("")
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ProductListView()
}
