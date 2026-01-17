import Foundation
import Combine

class NotificationViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadNotifications()
        loadPriceDrops()
    }
    
    func loadNotifications() {
        // Demo bildirimler
        let demoNotifications: [Notification] = [
            Notification(
                id: "1",
                type: .system,
                title: "ProductReview'a Hoş Geldiniz!",
                body: "İlk incelemelerinizi yapmaya başlayın.",
                timestamp: Date().addingTimeInterval(-1800), // 30 dakika önce
                isRead: false,
                productId: nil,
                productName: nil
            ),
            Notification(
                id: "2",
                type: .order,
                title: "Siparişiniz Yolda",
                body: "Sipariş #12345, 2-3 gün içinde teslim edilecektir.",
                timestamp: Date().addingTimeInterval(-7200), // 2 saat önce
                isRead: true,
                productId: nil,
                productName: nil
            ),
            Notification(
                id: "3",
                type: .priceDrop,
                title: "Fiyat Düşüşü Uyarısı! 📉",
                body: "iPhone 15 Pro Max artık 200$ daha ucuz! Eskiden 1299$, şimdi 1099$.",
                timestamp: Date().addingTimeInterval(-14400), // 4 saat önce
                isRead: false,
                productId: "1",
                productName: "iPhone 15 Pro Max"
            )
        ]
        
        notifications.append(contentsOf: demoNotifications)
    }
    
    func loadPriceDrops() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let priceDrops = try await APIService.getPriceDrops()
                
                let priceDropNotifications = priceDrops.map { drop in
                    Notification(
                        id: "price-drop-\(drop.id)",
                        type: .priceDrop,
                        title: "Fiyat Düşüşü Uyarısı! 📉",
                        body: "\(drop.productName) artık $\(String(format: "%.2f", drop.newPrice)) (eski fiyat: $\(String(format: "%.2f", drop.oldPrice)), %\(String(format: "%.1f", drop.changePercent)) indirim)",
                        timestamp: ISO8601DateFormatter().date(from: drop.changedAt) ?? Date(),
                        isRead: false,
                        productId: String(drop.productId),
                        productName: drop.productName
                    )
                }
                
                await MainActor.run {
                    // Duplicate kontrolü
                    let existingIds = Set(notifications.map { $0.id })
                    let newNotifications = priceDropNotifications.filter { !existingIds.contains($0.id) }
                    notifications.insert(contentsOf: newNotifications, at: 0)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    func markAsRead(_ id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
        }
    }
    
    func markAllAsRead() {
        for i in 0..<notifications.count {
            notifications[i].isRead = true
        }
    }
    
    func deleteNotification(_ id: String) {
        notifications.removeAll { $0.id == id }
    }
    
    func clearAll() {
        notifications.removeAll()
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
}