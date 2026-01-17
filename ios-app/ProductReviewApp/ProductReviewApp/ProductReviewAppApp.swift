import SwiftUI

struct ContentView: View {
    @StateObject private var notificationViewModel = NotificationViewModel()
    
    var body: some View {
        TabView {
            ProductListView()
                .tabItem {
                    Label("Ürünler", systemImage: "list.bullet")
                }
            
            NotificationView()
                .tabItem {
                    Label("Bildirimler", systemImage: "bell")
                }
                .badge(notificationViewModel.unreadCount > 0 ? Text("\(notificationViewModel.unreadCount)") : nil)
            
            WishlistView()
                .tabItem {
                    Label("Favoriler", systemImage: "heart")
                }
        }
        .environmentObject(notificationViewModel)
    }
}

#Preview {
    ContentView()
}

@main
struct ProductReviewAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
