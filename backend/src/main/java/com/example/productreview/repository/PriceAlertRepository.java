package com.example.productreview.repository;

import com.example.productreview.model.PriceAlert;
import com.example.productreview.model.Product;
import com.example.productreview.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PriceAlertRepository extends JpaRepository<PriceAlert, Long> {
    
    // Kullanıcının tüm aktif fiyat takiplerini getir
    List<PriceAlert> findByUserAndActiveTrue(User user);
    
    // Kullanıcının tüm fiyat takiplerini getir
    List<PriceAlert> findByUserOrderByCreatedAtDesc(User user);
    
    // Kullanıcının belirli bir üründeki takibini getir
    Optional<PriceAlert> findByUserAndProductAndActiveTrue(User user, Product product);
    
    // Bir ürün için aktif tüm takipleri getir (fiyat değiştiğinde bildirim göndermek için)
    List<PriceAlert> findByProductAndActiveTrueAndNotifiedFalse(Product product);
    
    // Hedef fiyatın altına düşmüş ürünleri bul
    @Query("SELECT pa FROM PriceAlert pa WHERE pa.active = true AND pa.notified = false " +
           "AND pa.product.price <= pa.targetPrice")
    List<PriceAlert> findAlertsBelowTargetPrice();
    
    // Kullanıcının aktif takip sayısı
    long countByUserAndActiveTrue(User user);
    
    // Ürünün toplam takipçi sayısı
    long countByProductAndActiveTrue(Product product);
}
