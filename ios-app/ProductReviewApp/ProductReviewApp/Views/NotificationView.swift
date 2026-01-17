import SwiftUI

struct NotificationView: View {
    @EnvironmentObject private var viewModel: NotificationViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Bildirimler yükleniyor...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else if let error = viewModel.error {
                    VStack {
                        Text("Hata: \(error)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Tekrar Dene") {
                            viewModel.loadPriceDrops()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else if viewModel.notifications.isEmpty {
                    VStack {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("Henüz bildirim yok")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRow(notification: notification)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let notification = viewModel.notifications[index]
                                viewModel.deleteNotification(notification.id)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Bildirimler")
            .navigationBarItems(
                leading: Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: HStack {
                    if viewModel.unreadCount > 0 {
                        Button("Tümünü Okundu İşaretle") {
                            viewModel.markAllAsRead()
                        }
                        .font(.caption)
                    }
                    
                    Button("Temizle") {
                        viewModel.clearAll()
                    }
                    .foregroundColor(.red)
                    .font(.caption)
                }
            )
        }
        .onAppear {
            viewModel.loadPriceDrops()
        }
    }
}

struct NotificationRow: View {
    let notification: Notification
    @EnvironmentObject var viewModel: NotificationViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // İkon
            ZStack {
                Circle()
                    .fill(notificationIconColor(notification.type).opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: notificationIcon(notification.type))
                    .foregroundColor(notificationIconColor(notification.type))
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Başlık ve zaman
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(notification.isRead ? .secondary : .primary)
                    
                    Spacer()
                    
                    Text(timeAgo(from: notification.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // İçerik
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.markAsRead(notification.id)
            // Fiyat düşüşü bildirimi ise ürün detayına git
            if notification.type == .priceDrop, let productId = notification.productId {
                // Navigation logic would go here
                print("Navigate to product: \(productId)")
            }
        }
        .background(
            notification.isRead ? Color.clear :
            Color.blue.opacity(0.1)
        )
        .cornerRadius(8)
        .padding(.horizontal, 4)
    }
    
    private func notificationIcon(_ type: NotificationType) -> String {
        switch type {
        case .review:
            return "star"
        case .order:
            return "cube.box"
        case .system:
            return "bell"
        case .priceDrop:
            return "arrow.down.circle"
        }
    }
    
    private func notificationIconColor(_ type: NotificationType) -> Color {
        switch type {
        case .review:
            return .blue
        case .order:
            return .green
        case .system:
            return .purple
        case .priceDrop:
            return .red
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "Dün" : "\(day)g"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)sa"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)dk"
        } else {
            return "Şimdi"
        }
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationView()
    }
}