package com.example.productreview.repository;

import com.example.productreview.model.PriceHistory;
import com.example.productreview.model.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PriceHistoryRepository extends JpaRepository<PriceHistory, Long> {
    
    // Ürünün fiyat geçmişi (son önce)
    Page<PriceHistory> findByProductOrderByChangedAtDesc(Product product, Pageable pageable);
    
    // Ürünün tüm fiyat geçmişi
    List<PriceHistory> findByProductOrderByChangedAtDesc(Product product);
    
    // Son N gündeki fiyat değişiklikleri
    @Query("SELECT ph FROM PriceHistory ph WHERE ph.product = :product AND ph.changedAt >= :since ORDER BY ph.changedAt DESC")
    List<PriceHistory> findByProductSince(Product product, LocalDateTime since);
    
    // Fiyat düşüşleri
    @Query("SELECT ph FROM PriceHistory ph WHERE ph.product = :product AND ph.newPrice < ph.oldPrice ORDER BY ph.changedAt DESC")
    List<PriceHistory> findPriceDropsByProduct(Product product);
    
    // Tüm ürünlerin son 24 saatteki fiyat düşüşleri
    @Query("SELECT ph FROM PriceHistory ph WHERE ph.changedAt >= :since AND ph.newPrice < ph.oldPrice ORDER BY ph.changedAt DESC")
    List<PriceHistory> findRecentPriceDrops(LocalDateTime since);
}
