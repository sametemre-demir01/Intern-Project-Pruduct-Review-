import SwiftUI

struct WishlistView: View {
    @State private var wishlistItems: [Product] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if wishlistItems.isEmpty {
                    VStack {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("Favori ürününüz yok")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Ürün detaylarından favorilerinize ekleyebilirsiniz")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                } else {
                    List(wishlistItems) { product in
                        HStack {
                            AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text(product.name)
                                    .font(.headline)
                                Text("$\(String(format: "%.2f", product.price))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                removeFromWishlist(product)
                            }) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Favoriler")
        }
        .onAppear {
            loadWishlist()
        }
    }
    
    private func loadWishlist() {
        // TODO: Favori ürünleri yükle
        // Şimdilik boş bırakıyoruz
    }
    
    private func removeFromWishlist(_ product: Product) {
        wishlistItems.removeAll { $0.id == product.id }
        // TODO: Favori listesinden kaldır
    }
}

struct WishlistView_Previews: PreviewProvider {
    static var previews: some View {
        WishlistView()
    }
}