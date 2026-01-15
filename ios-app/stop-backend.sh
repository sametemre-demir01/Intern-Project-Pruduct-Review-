#!/bin/bash

# iOS Product Review App - Backend Durdurma Script

echo "🛑 Backend durduruluyor..."

# Spring Boot process'ini bul ve durdur
pkill -f "spring-boot:run" && echo "✅ Backend durduruldu" || echo "⚠️ Çalışan backend bulunamadı"

# Port 8080'de çalışan process'i de kontrol et
if lsof -ti:8080 > /dev/null 2>&1; then
    echo "🔍 Port 8080'de hala process var, sonlandırılıyor..."
    kill $(lsof -ti:8080) 2>/dev/null && echo "✅ Port temizlendi"
fi

echo "✨ Tamamlandı"
