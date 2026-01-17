#!/bin/bash

# iOS Uygulamasını Simülatörde Başlat
# Kullanım: ./start-ios.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/ProductReviewApp"
SCHEME="ProductReviewApp"
SIMULATOR_NAME="iPhone 17 Pro"

echo "🍎 iOS Uygulaması Başlatılıyor..."
echo ""

# Xcode yüklü mü kontrol et
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode yüklü değil. App Store'dan Xcode'u yükleyin."
    exit 1
fi

# Xcode projesi var mı kontrol et
XCODEPROJ=$(find "$PROJECT_DIR" -maxdepth 1 -name "*.xcodeproj" -type d | head -1)

if [ -z "$XCODEPROJ" ]; then
    echo "⚠️  Xcode projesi bulunamadı!"
    echo ""
    echo "📝 Xcode projesi oluşturmak için:"
    echo "   1. Xcode'u aç"
    echo "   2. File → New → Project"
    echo "   3. iOS → App seç"
    echo "   4. Product Name: ProductReviewApp"
    echo "   5. Interface: SwiftUI, Language: Swift"
    echo "   6. Kayıt yeri: $(pwd)/ios-app"
    echo "   7. ProductReviewApp klasöründeki dosyaları projeye ekle"
    echo ""
    echo "Detaylı rehber: ios-app/SETUP.md"
    exit 1
fi

echo "📱 Proje: $XCODEPROJ"

# Mevcut simülatörleri listele ve uygun olanı bul
SIMULATOR_UDID=$(xcrun simctl list devices available | grep -E "iPhone (17|16|15|14)" | head -1 | grep -oE '[A-F0-9-]{36}')

if [ -z "$SIMULATOR_UDID" ]; then
    echo "❌ Uygun iPhone simülatörü bulunamadı!"
    echo "Mevcut simülatörler:"
    xcrun simctl list devices available | grep iPhone
    exit 1
fi

SIMULATOR_NAME=$(xcrun simctl list devices available | grep "$SIMULATOR_UDID" | sed 's/(.*//' | xargs)
echo "📱 Simülatör: $SIMULATOR_NAME"

# Simülatörü başlat
echo "🚀 Simülatör başlatılıyor..."
xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
open -a Simulator

# Projeyi derle ve çalıştır
echo "🔨 Uygulama derleniyor..."
cd "$PROJECT_DIR"

xcodebuild -project "$(basename "$XCODEPROJ")" \
    -scheme "$SCHEME" \
    -destination "id=$SIMULATOR_UDID" \
    -configuration Debug \
    build 2>&1 | tail -20

# Uygulamayı simülatöre yükle ve çalıştır
echo "📲 Uygulama yükleniyor ve başlatılıyor..."

# Build klasörünü bul
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "ProductReviewApp.app" -type d | head -1)

if [ -n "$APP_PATH" ]; then
    xcrun simctl install "$SIMULATOR_UDID" "$APP_PATH"
    xcrun simctl launch "$SIMULATOR_UDID" com.example.ProductReviewApp
    echo ""
    echo "✅ iOS uygulaması simülatörde çalışıyor!"
    echo "📍 Backend: http://localhost:8080"
else
    echo "⚠️  Uygulama build edildi ama .app dosyası bulunamadı."
    echo "Xcode'dan manuel olarak çalıştırın: Cmd + R"
fi
