package com.example.productreview.controller;

import com.example.productreview.dto.PriceAlertDTO;
import com.example.productreview.model.PriceHistory;
import com.example.productreview.service.PriceAlertService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/price-alerts")
@CrossOrigin(origins = "*")
public class PriceAlertController {
    
    private final PriceAlertService priceAlertService;

    public PriceAlertController(PriceAlertService priceAlertService) {
        this.priceAlertService = priceAlertService;
    }

    /**
     * Yeni fiyat takibi oluştur
     * POST /api/price-alerts
     * Body: { "productId": 1, "targetPrice": 899.99 }
     */
    @PostMapping
    public ResponseEntity<?> createAlert(
            @RequestBody Map<String, Object> request,
            Authentication authentication) {
        
        if (authentication == null) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Fiyat takibi için giriş yapmalısınız"));
        }
        
        try {
            Long productId = ((Number) request.get("productId")).longValue();
            Double targetPrice = ((Number) request.get("targetPrice")).doubleValue();
            String userEmail = authentication.getName();
            
            PriceAlertDTO alert = priceAlertService.createPriceAlert(userEmail, productId, targetPrice);
            return ResponseEntity.ok(alert);
            
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Kullanıcının fiyat takiplerini getir
     * GET /api/price-alerts
     */
    @GetMapping
    public ResponseEntity<?> getMyAlerts(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Giriş yapmalısınız"));
        }
        
        List<PriceAlertDTO> alerts = priceAlertService.getUserAlerts(authentication.getName());
        return ResponseEntity.ok(alerts);
    }

    /**
     * Fiyat takibini iptal et
     * DELETE /api/price-alerts/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> cancelAlert(
            @PathVariable Long id,
            Authentication authentication) {
        
        if (authentication == null) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", "Giriş yapmalısınız"));
        }
        
        try {
            priceAlertService.cancelAlert(authentication.getName(), id);
            return ResponseEntity.ok(Map.of("message", "Fiyat takibi iptal edildi"));
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Ürünün fiyat geçmişini getir (herkese açık)
     * GET /api/price-alerts/history/{productId}
     */
    @GetMapping("/history/{productId}")
    public ResponseEntity<?> getPriceHistory(@PathVariable Long productId) {
        try {
            List<PriceHistory> history = priceAlertService.getPriceHistory(productId);
            return ResponseEntity.ok(history.stream().map(h -> Map.of(
                    "id", h.getId(),
                    "oldPrice", h.getOldPrice(),
                    "newPrice", h.getNewPrice(),
                    "changePercent", h.getChangePercent() != null ? h.getChangePercent() : 0,
                    "changedAt", h.getChangedAt().toString(),
                    "isPriceDrop", h.isPriceDrop()
            )).toList());
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Son 24 saatteki fiyat düşüşleri (herkese açık)
     * GET /api/price-alerts/drops
     */
    @GetMapping("/drops")
    public ResponseEntity<?> getRecentDrops() {
        List<PriceHistory> drops = priceAlertService.getRecentPriceDrops();
        return ResponseEntity.ok(drops.stream().map(h -> Map.of(
                "productId", h.getProduct().getId(),
                "productName", h.getProduct().getName(),
                "oldPrice", h.getOldPrice(),
                "newPrice", h.getNewPrice(),
                "changePercent", h.getChangePercent() != null ? h.getChangePercent() : 0,
                "changedAt", h.getChangedAt().toString()
        )).toList());
    }
}
