package com.example.productreview.dto;

import java.time.LocalDateTime;

public class PriceAlertDTO {
    private Long id;
    private Long productId;
    private String productName;
    private String productImageUrl;
    private Double targetPrice;
    private Double originalPrice;
    private Double currentPrice;
    private Boolean active;
    private Boolean notified;
    private LocalDateTime createdAt;
    private LocalDateTime notifiedAt;
    private Double priceDropPercent;
    
    public PriceAlertDTO() {}
    
    public PriceAlertDTO(Long id, Long productId, String productName, String productImageUrl,
                         Double targetPrice, Double originalPrice, Double currentPrice,
                         Boolean active, Boolean notified, LocalDateTime createdAt, LocalDateTime notifiedAt) {
        this.id = id;
        this.productId = productId;
        this.productName = productName;
        this.productImageUrl = productImageUrl;
        this.targetPrice = targetPrice;
        this.originalPrice = originalPrice;
        this.currentPrice = currentPrice;
        this.active = active;
        this.notified = notified;
        this.createdAt = createdAt;
        this.notifiedAt = notifiedAt;
        
        if (originalPrice != null && currentPrice != null && originalPrice > 0) {
            this.priceDropPercent = ((originalPrice - currentPrice) / originalPrice) * 100;
        }
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Long getProductId() {
        return productId;
    }
    
    public void setProductId(Long productId) {
        this.productId = productId;
    }
    
    public String getProductName() {
        return productName;
    }
    
    public void setProductName(String productName) {
        this.productName = productName;
    }
    
    public String getProductImageUrl() {
        return productImageUrl;
    }
    
    public void setProductImageUrl(String productImageUrl) {
        this.productImageUrl = productImageUrl;
    }
    
    public Double getTargetPrice() {
        return targetPrice;
    }
    
    public void setTargetPrice(Double targetPrice) {
        this.targetPrice = targetPrice;
    }
    
    public Double getOriginalPrice() {
        return originalPrice;
    }
    
    public void setOriginalPrice(Double originalPrice) {
        this.originalPrice = originalPrice;
    }
    
    public Double getCurrentPrice() {
        return currentPrice;
    }
    
    public void setCurrentPrice(Double currentPrice) {
        this.currentPrice = currentPrice;
    }
    
    public Boolean getActive() {
        return active;
    }
    
    public void setActive(Boolean active) {
        this.active = active;
    }
    
    public Boolean getNotified() {
        return notified;
    }
    
    public void setNotified(Boolean notified) {
        this.notified = notified;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getNotifiedAt() {
        return notifiedAt;
    }
    
    public void setNotifiedAt(LocalDateTime notifiedAt) {
        this.notifiedAt = notifiedAt;
    }
    
    public Double getPriceDropPercent() {
        return priceDropPercent;
    }
    
    public void setPriceDropPercent(Double priceDropPercent) {
        this.priceDropPercent = priceDropPercent;
    }
    
    // Helper method
    public boolean isTargetReached() {
        return currentPrice != null && targetPrice != null && currentPrice <= targetPrice;
    }
}
