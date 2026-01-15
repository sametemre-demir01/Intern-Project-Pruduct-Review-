package com.example.productreview.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Fiyat geçmişi - ürün fiyat değişikliklerini takip etmek için
 */
@Entity
@Table(name = "price_history")
public class PriceHistory {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;
    
    @Column(nullable = false)
    private Double oldPrice;
    
    @Column(nullable = false)
    private Double newPrice;
    
    @Column(nullable = false)
    private LocalDateTime changedAt;
    
    // Fiyat değişim yüzdesi (negatif = düşüş, pozitif = artış)
    private Double changePercent;
    
    @PrePersist
    protected void onCreate() {
        changedAt = LocalDateTime.now();
        if (oldPrice != null && oldPrice > 0) {
            changePercent = ((newPrice - oldPrice) / oldPrice) * 100;
        }
    }
    
    // Constructors
    public PriceHistory() {}
    
    public PriceHistory(Product product, Double oldPrice, Double newPrice) {
        this.product = product;
        this.oldPrice = oldPrice;
        this.newPrice = newPrice;
    }
    
    // Getters and Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public Product getProduct() {
        return product;
    }
    
    public void setProduct(Product product) {
        this.product = product;
    }
    
    public Double getOldPrice() {
        return oldPrice;
    }
    
    public void setOldPrice(Double oldPrice) {
        this.oldPrice = oldPrice;
    }
    
    public Double getNewPrice() {
        return newPrice;
    }
    
    public void setNewPrice(Double newPrice) {
        this.newPrice = newPrice;
    }
    
    public LocalDateTime getChangedAt() {
        return changedAt;
    }
    
    public void setChangedAt(LocalDateTime changedAt) {
        this.changedAt = changedAt;
    }
    
    public Double getChangePercent() {
        return changePercent;
    }
    
    public void setChangePercent(Double changePercent) {
        this.changePercent = changePercent;
    }
    
    // Helper method
    public boolean isPriceDrop() {
        return newPrice < oldPrice;
    }
}
