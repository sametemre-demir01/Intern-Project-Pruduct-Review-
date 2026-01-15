#!/bin/bash

# Product Review App - Development Başlatma Scripti
# Bu script backend ve mobile uygulamalarını birlikte başlatır

echo "🚀 Product Review App Başlatılıyor..."

# Eski işlemleri temizle
echo "🧹 Eski işlemler temizleniyor..."
lsof -ti:8080 | xargs kill -9 2>/dev/null
lsof -ti:8081 | xargs kill -9 2>/dev/null

# JAVA_HOME ayarla
export JAVA_HOME=$(/usr/libexec/java_home)

# Backend'i arka planda başlat
echo "☕ Backend başlatılıyor (port 8080)..."
cd "$(dirname "$0")/backend"
mvn spring-boot:run &
BACKEND_PID=$!

# Backend'in başlamasını bekle
echo "⏳ Backend'in hazır olması bekleniyor..."
sleep 15

# Backend'in çalışıp çalışmadığını kontrol et
if curl -s http://localhost:8080/api/products > /dev/null 2>&1; then
    echo "✅ Backend hazır!"
else
    echo "⚠️  Backend henüz hazır değil, devam ediliyor..."
fi

# Mobile uygulamayı başlat
echo "📱 Mobile uygulama başlatılıyor (port 8081)..."
cd "$(dirname "$0")/mobile"
npm start

# Script kapandığında backend'i de kapat
trap "kill $BACKEND_PID 2>/dev/null" EXIT
