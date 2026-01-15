# iOS Product Review App

SwiftUI ile geliştirilmiş native iOS ürün inceleme uygulaması.

## 📋 Gereksinimler

- **Xcode 15.0+**
- **iOS 17.0+**
- **Swift 5.9+**
- **macOS 14.0+ (Xcode için)**

## 🚀 Kurulum

### 1. Xcode Projesi Oluşturma

1. Xcode'u açın
2. File → New → Project seçin
3. iOS → App seçin
4. Proje ayarları:
   - **Product Name**: ProductReviewApp
   - **Team**: Kişisel Apple Developer hesabınızı seçin
   - **Organization Identifier**: com.example (veya kendi domain'iniz)
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None
5. Proje konumu olarak `ios-app` klasörünü seçin

### 2. Dosyaları Projeye Ekleme

Aşağıdaki klasörleri Xcode projesine sürükleyip bırakın:

```
ProductReviewApp/
├── App/
│   └── ProductReviewApp.swift
├── Models/
│   ├── Product.swift
│   └── Review.swift
├── Views/
│   ├── ProductListView.swift
│   └── ProductDetailView.swift
├── ViewModels/
│   ├── ProductListViewModel.swift
│   └── ProductDetailViewModel.swift
└── Services/
    └── APIService.swift
```

### 3. Info.plist Ayarları

Info.plist dosyasını açın ve aşağıdaki ayarları ekleyin (localhost bağlantısı için):

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

**Not**: Production ortamında `NSAllowsArbitraryLoads` kullanmayın, HTTPS kullanın.

### 4. Backend Bağlantısı

Backend API varsayılan olarak `http://localhost:8080` adresinde çalışır.

Farklı bir adres kullanıyorsanız, `APIService.swift` dosyasındaki `baseURL` değerini güncelleyin:

```swift
init(baseURL: String = "http://YOUR_IP_ADDRESS:8080") {
    self.baseURL = baseURL
    // ...
}
```

**Önemli**: iOS Simulator'da `localhost` kullanabilirsiniz, ancak gerçek cihazda backend'in network IP adresini kullanmalısınız.

## 🏃‍♂️ Uygulamayı Çalıştırma

### Backend'i Başlatma

1. Backend klasörüne gidin:
```bash
cd ../backend
./mvnw spring-boot:run
```

2. Backend'in çalıştığını doğrulayın:
```bash
curl http://localhost:8080/api/products
```

### iOS Uygulamasını Başlatma

1. Xcode'da projeyi açın
2. Simulator veya gerçek cihaz seçin
3. ▶️ (Run) butonuna basın veya `Cmd + R`

## 📱 Özellikler

### ✅ Tamamlanan Özellikler

- [x] Ürün listesi görüntüleme
- [x] Sayfalama (infinite scroll)
- [x] Kategoriye göre filtreleme
- [x] Ürün arama
- [x] Ürün detay sayfası
- [x] Yorum listesi (pagination)
- [x] Yeni yorum ekleme
- [x] AI özet gösterimi
- [x] Puan dağılımı
- [x] Responsive tasarım

### 🎨 UI Bileşenleri

- **ProductListView**: Ana ürün listesi ve filtreleme
- **ProductDetailView**: Detaylı ürün bilgisi ve yorumlar
- **ReviewCardView**: Yorum kartları
- **SearchBarView**: Arama çubuğu
- **FilterButtonView**: Kategori filtreleri

## 🏗️ Mimari

### MVVM (Model-View-ViewModel)

```
Models/          → Veri modelleri (Product, Review)
Views/           → SwiftUI görünümleri
ViewModels/      → İş mantığı ve state yönetimi
Services/        → API iletişimi
```

### Veri Akışı

```
View → ViewModel → APIService → Backend API
  ↑        ↓
  ←────────
  @Published
```

## 🔧 Yapılandırma

### API Endpoint'leri

- `GET /api/products` - Ürün listesi
- `GET /api/products/{id}` - Ürün detayı
- `GET /api/products/{id}/reviews` - Yorumlar
- `POST /api/products/{id}/reviews` - Yorum ekle

### Varsayılan Ayarlar

- Sayfa başına ürün: 10
- Sayfa başına yorum: 5
- Timeout: 30 saniye

## 🐛 Sorun Giderme

### Backend'e bağlanamıyor

1. Backend'in çalıştığını kontrol edin
2. Info.plist'te `NSAppTransportSecurity` ayarlarını kontrol edin
3. Gerçek cihazda network IP kullanıyor musunuz?

### Görüntüler yüklenmiyor

1. Backend'deki `imageUrl` alanlarını kontrol edin
2. URL'lerin geçerli olduğundan emin olun
3. Network bağlantısını kontrol edin

### Xcode Build Hataları

1. Proje ayarlarında iOS Deployment Target'ı kontrol edin (iOS 17.0+)
2. Tüm dosyaların Target'a eklendiğinden emin olun
3. Clean Build Folder: `Cmd + Shift + K`

## 📝 Geliştirme Notları

### Async/Await Kullanımı

Tüm network işlemleri async/await pattern'i kullanır:

```swift
Task {
    await viewModel.fetchProducts()
}
```

### State Yönetimi

- `@StateObject` - ViewModel'leri oluşturmak için
- `@Published` - Reactive değişkenler için
- `@State` - Local UI state için

### Codable Protokolü

Tüm modeller `Codable` protokolünü implement eder (JSON serialization).

## 🔮 Gelecek Geliştirmeler

- [ ] Offline cache (CoreData/Realm)
- [ ] Favori ürünler (UserDefaults/Keychain)
- [ ] Dark mode desteği
- [ ] Ürün karşılaştırma
- [ ] Push notifications
- [ ] Biometric authentication
- [ ] Widget desteği
- [ ] Unit ve UI testleri

## 📚 Kaynaklar

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [URLSession](https://developer.apple.com/documentation/foundation/urlsession)

## 📄 Lisans

MIT License - Detaylar için LICENSE dosyasına bakın.
