#!/bin/bash

# iOS Product Review App - Backend Başlatma Script

echo "🚀 Backend başlatılıyor..."

# Backend klasörüne git
cd "$(dirname "$0")/../backend"

# Backend'in zaten çalışıp çalışmadığını kontrol et
if curl -s http://localhost:8080/api/products > /dev/null 2>&1; then
    echo "✅ Backend zaten çalışıyor!"
    echo "📍 API: http://localhost:8080/api/products"
    exit 0
fi

# Java kurulu mu kontrol et
if ! command -v java &> /dev/null; then
    echo "❌ Java bulunamadı. Lütfen Java 17 veya üstünü kurunuz."
    exit 1
fi

echo "📦 Maven kullanılarak backend başlatılıyor..."

# Maven ile backend'i başlat
if command -v mvn &> /dev/null; then
    # Maven kurulu
    nohup mvn spring-boot:run > backend.log 2>&1 &
else
    # Maven wrapper kullan
    nohup ./mvnw spring-boot:run > backend.log 2>&1 &
fi

echo "⏳ Backend'in başlaması bekleniyor..."
sleep 5

# Backend'in başladığını kontrol et
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:8080/api/products > /dev/null 2>&1; then
        echo "✅ Backend başarıyla başlatıldı!"
        echo "📍 API Endpoint: http://localhost:8080/api/products"
        echo "📊 H2 Console: http://localhost:8080/h2-console"
        echo "📝 Loglar: backend/backend.log"
        exit 0
    fi
    
    echo "⏳ Bekleniyor... ($((ATTEMPT+1))/$MAX_ATTEMPTS)"
    sleep 2
    ATTEMPT=$((ATTEMPT+1))
done

echo "❌ Backend başlatılamadı. Lütfen backend.log dosyasını kontrol edin."
exit 1
