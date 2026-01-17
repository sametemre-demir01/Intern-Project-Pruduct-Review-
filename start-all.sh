#!/bin/bash

echo "🚀 Product Review Projesi Başlatılıyor..."
echo ""

# Backend başlat
echo "1️⃣ Backend başlatılıyor (port 8080)..."
cd /Users/aybukedemir/Desktop/intern-project-product-review-main/backend
mvn spring-boot:run &
BACKEND_PID=$!

# Backend'in hazır olmasını bekle
echo "   ⏳ Backend hazırlanıyor..."
sleep 10

# React Native Web başlat
echo "2️⃣ React Native Web başlatılıyor (port 8081)..."
cd /Users/aybukedemir/Desktop/intern-project-product-review-main/mobile
npx expo start --web &
EXPO_PID=$!

sleep 5

echo ""
echo "✅ Backend ve Web sitesi başlatıldı!"
echo ""
echo "📱 Adresler:"
echo "   • Backend API:  http://localhost:8080"
echo "   • Web App:      http://localhost:8081"
echo ""
echo "🌐 Web sitesi tarayıcıda açılıyor..."
open http://localhost:8081
echo ""
echo "📱 iOS Simülatörü için ayrı terminalde:"
echo "   cd ~/Desktop/intern-project-product-review-main/ios-app && ./start-ios.sh"
echo ""
echo "🛑 Durdurmak için: Ctrl+C"

wait
