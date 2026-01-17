import SwiftUI
//ana ürün listesi ekranını temsil eder,
//ürünleri listeler, arama ve kategori filtresi sağlar,
struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Ürün ara...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            viewModel.searchText = searchText
                            Task {
                                await viewModel.search()
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.searchText = ""
                            Task {
                                await viewModel.search()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Karşılaştır Butonu
                    Button(action: {
                        viewModel.startSelectionMode()
                    }) {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundColor(.blue)
                    }
                    
                    // Grid Mode Toggle
                    Button(action: {
                        viewModel.toggleGridMode()
                    }) {
                        Image(systemName: viewModel.gridMode == 1 ? "list.bullet" : viewModel.gridMode == 2 ? "square.grid.2x2" : "square.grid.4x4")
                            .foregroundColor(.blue)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Comparison Bar
                if viewModel.isSelectionMode {
                    HStack {
                        Button("İptal") {
                            viewModel.clearSelection()
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Text("\(viewModel.selectedProducts.count) ürün seçildi")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if viewModel.selectedProducts.count >= 2 {
                            NavigationLink(destination: ProductComparisonView(viewModel: viewModel)) {
                                Text("Karşılaştır")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                } else {
                    HStack {
                        Spacer()
                        Button("Karşılaştır") {
                            viewModel.startSelectionMode()
                        }
                        .foregroundColor(.blue)
                        .padding(.trailing)
                    }
                    .padding(.horizontal)
                }
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryButton(
                            title: "Tümü",
                            isSelected: viewModel.selectedCategory.isEmpty
                        ) {
                            Task {
                                await viewModel.filterByCategory("")
                            }
                        }
                        
                        ForEach(viewModel.categories, id: \.self) { category in
                            CategoryButton(
                                title: category,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                Task {
                                    await viewModel.filterByCategory(category)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Product List
                if viewModel.isLoading && viewModel.products.isEmpty {
                    Spacer()
                    ProgressView("Yükleniyor...")
                    Spacer()
                } else if let error = viewModel.error {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("Tekrar Dene") {
                            Task {
                                await viewModel.loadProducts(reset: true)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else if viewModel.products.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "cube.box")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Ürün bulunamadı")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: viewModel.gridMode)
                        
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(viewModel.products) { product in
                                if viewModel.isSelectionMode {
                                    ProductCardView(
                                        product: product,
                                        isSelectionMode: true,
                                        isSelected: viewModel.selectedProducts.contains(product.id)
                                    ) {
                                        viewModel.toggleSelection(for: product.id)
                                    }
                                } else {
                                    NavigationLink(destination: ProductDetailView(productId: product.id)) {
                                        ProductCardView(product: product)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Load More
                            if viewModel.hasMorePages {
                                ProgressView()
                                    .padding()
                                    .onAppear {
                                        Task {
                                            await viewModel.loadMore()
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Ürünler")
            .task {
                await viewModel.loadCategories()
                await viewModel.loadProducts(reset: true)
            }
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ProductCardView: View {
    let product: Product
    var isSelectionMode = false
    var isSelected = false
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            
            // Product Image
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
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
            }
            
            if !isSelectionMode {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap?()
        }
    }
}

#Preview {
    ProductListView()
}
