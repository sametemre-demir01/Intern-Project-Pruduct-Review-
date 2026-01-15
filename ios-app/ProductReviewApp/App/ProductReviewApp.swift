import SwiftUI

@main
struct ProductReviewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            // Ürünler Sekmesi
            ProductListView()
                .tabItem {
                    Label("Ürünler", systemImage: "list.bullet")
                }
            
            // Favoriler Sekmesi (ileride genişletilebilir)
            WishlistView()
                .tabItem {
                    Label("Favoriler", systemImage: "heart")
                }
        }
    }
}

struct WishlistView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("Favori Ürünler")
                .font(.headline)
            
            Text("Beğendiğiniz ürünleri buraya ekleyebilirsiniz")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Favoriler")
    }
}

#Preview {
    ContentView()
}
