package com.example.productreview.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Fiyat takip kaydı - kullanıcının bir ürünün fiyatını takip etmesi için
 */
@Entity
@Table(name = "price_alerts")
public class PriceAlert {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id", nullable = false)
    private Product product;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    // Hedef fiyat - bu fiyatın altına düşünce bildirim gönder
    @Column(nullable = false)
    private Double targetPrice;
    
    // Ürünün takibe alındığındaki fiyatı
    @Column(nullable = false)
    private Double originalPrice;
    
    // Takip aktif mi?
    @Column(nullable = false)
    private Boolean active = true;
    
    // Bildirim gönderildi mi?
    @Column(nullable = false)
    private Boolean notified = false;
    
    @Column(nullable = false)
    private LocalDateTime createdAt;
    
    private LocalDateTime notifiedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Constructors
    public PriceAlert() {}
    
    public PriceAlert(Product product, User user, Double targetPrice, Double originalPrice) {
        this.product = product;
        this.user = user;
        this.targetPrice = targetPrice;
        this.originalPrice = originalPrice;
        this.active = true;
        this.notified = false;
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
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
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
}
