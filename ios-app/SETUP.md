# iOS Proje Kurulum Rehberi

Bu rehber, iOS uygulamasını Xcode'da sıfırdan kurmak için adım adım talimatlar içerir.

## Adım 1: Xcode Projesi Oluşturma

1. **Xcode'u açın**
2. **"Create a new Xcode project"** seçin
3. **iOS → App** şablonunu seçin
4. **Next** butonuna tıklayın

### Proje Ayarları

Aşağıdaki bilgileri girin:

| Alan | Değer |
|------|-------|
| Product Name | `ProductReviewApp` |
| Team | Kişisel hesabınızı seçin |
| Organization Identifier | `com.example` |
| Bundle Identifier | Otomatik oluşur |
| Interface | `SwiftUI` |
| Language | `Swift` |
| Storage | `None` |

5. **Next** butonuna tıklayın
6. Kayıt konumu olarak `ios-app` klasörünü seçin
7. **Create** butonuna tıklayın

## Adım 2: Proje Yapısını Düzenleme

### 2.1 Varsayılan Dosyaları Silme

Xcode'un oluşturduğu şu dosyaları silin:
- `ContentView.swift` (bizim dosyalarımızı kullanacağız)

### 2.2 Grup (Folder) Oluşturma

Xcode'da sol panelde (Project Navigator) projeye sağ tıklayın ve **New Group** seçin. Aşağıdaki grupları oluşturun:

- ✅ App (zaten var)
- ✅ Models
- ✅ Views
- ✅ ViewModels
- ✅ Services
- ✅ Resources (opsiyonel)

## Adım 3: Dosyaları Projeye Ekleme

### 3.1 Dosyaları Kopyalama

Finder'da `ProductReviewApp` klasöründeki dosyaları Xcode'daki ilgili gruplara sürükleyin:

**App/**
- `ProductReviewApp.swift` → App grubuna

**Models/**
- `Product.swift` → Models grubuna
- `Review.swift` → Models grubuna

**Views/**
- `ProductListView.swift` → Views grubuna
- `ProductDetailView.swift` → Views grubuna

**ViewModels/**
- `ProductListViewModel.swift` → ViewModels grubuna
- `ProductDetailViewModel.swift` → ViewModels grubuna

**Services/**
- `APIService.swift` → Services grubuna

### 3.2 Import Seçenekleri

Dosyaları sürüklerken açılan pencerede:
- ✅ **Copy items if needed** işaretleyin
- ✅ **Create groups** seçili olsun
- ✅ **Add to targets: ProductReviewApp** işaretli olsun

## Adım 4: Info.plist Yapılandırması

### 4.1 Info.plist Dosyasını Bulma

1. Project Navigator'da projeye tıklayın
2. Targets altında **ProductReviewApp** seçin
3. **Info** sekmesine gidin

### 4.2 HTTP Bağlantısına İzin Verme

**Yöntem 1: Xcode UI ile**

1. Info sekmesinde **+** butonuna tıklayın
2. **App Transport Security Settings** ekleyin
3. Bu satırı genişletin ve **+** tıklayın
4. **Allow Arbitrary Loads** ekleyin ve **YES** yapın
5. Tekrar **+** tıklayın
6. **Allow Local Networking** ekleyin ve **YES** yapın

**Yöntem 2: Doğrudan Info.plist düzenleme**

1. Project Navigator'da `Info.plist` dosyasını sağ tıklayın
2. **Open As → Source Code** seçin
3. Aşağıdaki kodu `<dict>` içine ekleyin:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## Adım 5: Build Settings Kontrolü

1. Project Navigator'da projeye tıklayın
2. Targets → **ProductReviewApp** seçin
3. **Build Settings** sekmesine gidin
4. **iOS Deployment Target**'ı kontrol edin: **iOS 17.0** veya üzeri

## Adım 6: İlk Build

1. **Product → Clean Build Folder** (`Cmd + Shift + K`)
2. Simulator seçin (örn: iPhone 15 Pro)
3. **Product → Build** (`Cmd + B`)
4. Hataları kontrol edin ve düzeltin

## Adım 7: Backend'i Başlatma

Terminal açın ve backend'i başlatın:

```bash
cd /Users/aybukedemir/Desktop/intern-project-product-review-main/backend
./mvnw spring-boot:run
```

Backend'in çalıştığını doğrulayın:
```bash
curl http://localhost:8080/api/products
```

## Adım 8: Uygulamayı Çalıştırma

1. Xcode'da **Product → Run** (`Cmd + R`)
2. Simulator'da uygulamanın açıldığını görün
3. Ürünlerin yüklendiğini kontrol edin

## Gerçek Cihazda Çalıştırma

### iPhone/iPad'de Test Etme

1. **Device'ı Mac'e bağlayın**
2. Xcode'da üst menüden cihazınızı seçin
3. **Signing & Capabilities** sekmesine gidin
4. **Team** seçin (Apple ID hesabınız)
5. **Automatically manage signing** işaretleyin
6. **Run** butonuna basın

### Network Ayarları

Gerçek cihazda backend'e erişmek için:

1. Mac'inizin local network IP'sini bulun:
```bash
ipconfig getifaddr en0
```

2. `APIService.swift` dosyasını düzenleyin:
```swift
init(baseURL: String = "http://192.168.1.XXX:8080") {
    // IP'nizi buraya yazın
}
```

3. iPhone ve Mac'in **aynı WiFi ağında** olduğundan emin olun

## Sorun Giderme

### "No such module 'SwiftUI'"
- Deployment target iOS 17.0+ olmalı

### "Untrusted Developer"
- Ayarlar → Genel → Cihaz Yönetimi → Developer App'e güven

### Backend'e bağlanamıyor
- Info.plist'te App Transport Security ayarlarını kontrol edin
- Backend'in çalıştığından emin olun
- Gerçek cihazda IP adresini kullanın

### Build hatası
- Clean Build Folder (`Cmd + Shift + K`)
- Derived Data'yı silin
- Xcode'u yeniden başlatın

## Tamamlandı! 🎉

Artık iOS uygulamanız çalışıyor olmalı. Ürünleri görüntüleyebilir, detaylara bakabilir ve yorum ekleyebilirsiniz.
