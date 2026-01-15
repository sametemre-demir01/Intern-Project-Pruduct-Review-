package com.example.productreview.service;

import com.example.productreview.dto.PriceAlertDTO;
import com.example.productreview.model.PriceAlert;
import com.example.productreview.model.PriceHistory;
import com.example.productreview.model.Product;
import com.example.productreview.model.User;
import com.example.productreview.repository.PriceAlertRepository;
import com.example.productreview.repository.PriceHistoryRepository;
import com.example.productreview.repository.ProductRepository;
import com.example.productreview.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class PriceAlertService {
    
    private static final Logger log = LoggerFactory.getLogger(PriceAlertService.class);
    
    private final PriceAlertRepository priceAlertRepository;
    private final PriceHistoryRepository priceHistoryRepository;
    private final ProductRepository productRepository;
    private final UserRepository userRepository;

    public PriceAlertService(PriceAlertRepository priceAlertRepository, 
                             PriceHistoryRepository priceHistoryRepository,
                             ProductRepository productRepository,
                             UserRepository userRepository) {
        this.priceAlertRepository = priceAlertRepository;
        this.priceHistoryRepository = priceHistoryRepository;
        this.productRepository = productRepository;
        this.userRepository = userRepository;
    }

    /**
     * Yeni fiyat takibi oluştur
     */
    @Transactional
    public PriceAlertDTO createPriceAlert(String userEmail, Long productId, Double targetPrice) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı: " + userEmail));
        
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Ürün bulunamadı: " + productId));
        
        // Mevcut aktif takip var mı kontrol et
        priceAlertRepository.findByUserAndProductAndActiveTrue(user, product)
                .ifPresent(existing -> {
                    throw new RuntimeException("Bu ürün için zaten aktif bir fiyat takibiniz var");
                });
        
        PriceAlert alert = new PriceAlert(product, user, targetPrice, product.getPrice());
        alert = priceAlertRepository.save(alert);
        
        log.info("✅ Fiyat takibi oluşturuldu: {} için {} TL hedef (kullanıcı: {})", 
                product.getName(), targetPrice, userEmail);
        
        return convertToDTO(alert);
    }

    /**
     * Kullanıcının fiyat takiplerini getir
     */
    public List<PriceAlertDTO> getUserAlerts(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı: " + userEmail));
        
        return priceAlertRepository.findByUserOrderByCreatedAtDesc(user)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Fiyat takibini iptal et
     */
    @Transactional
    public void cancelAlert(String userEmail, Long alertId) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new RuntimeException("Kullanıcı bulunamadı: " + userEmail));
        
        PriceAlert alert = priceAlertRepository.findById(alertId)
                .orElseThrow(() -> new RuntimeException("Fiyat takibi bulunamadı: " + alertId));
        
        if (!alert.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("Bu fiyat takibi size ait değil");
        }
        
        alert.setActive(false);
        priceAlertRepository.save(alert);
        
        log.info("❌ Fiyat takibi iptal edildi: {} (kullanıcı: {})", alertId, userEmail);
    }

    /**
     * Ürün fiyatı değiştiğinde çağrılır
     */
    @Transactional
    public void onPriceChange(Product product, Double oldPrice, Double newPrice) {
        // Fiyat geçmişine kaydet
        PriceHistory history = new PriceHistory(product, oldPrice, newPrice);
        priceHistoryRepository.save(history);
        
        log.info("📊 Fiyat değişikliği kaydedildi: {} {} -> {} TL", 
                product.getName(), oldPrice, newPrice);
        
        // Fiyat düştüyse bildirimleri kontrol et
        if (newPrice < oldPrice) {
            checkAndNotifyAlerts(product, newPrice);
        }
    }

    /**
     * Hedef fiyata ulaşan takipleri bildirime gönder
     */
    private void checkAndNotifyAlerts(Product product, Double newPrice) {
        List<PriceAlert> alerts = priceAlertRepository.findByProductAndActiveTrueAndNotifiedFalse(product);
        
        for (PriceAlert alert : alerts) {
            if (newPrice <= alert.getTargetPrice()) {
                alert.setNotified(true);
                alert.setNotifiedAt(LocalDateTime.now());
                priceAlertRepository.save(alert);
                
                // Burada gerçek bildirim gönderme işlemi yapılabilir (email, push notification vb.)
                log.info("🔔 Fiyat bildirimi gönderildi: {} - {} TL (hedef: {} TL) -> kullanıcı: {}", 
                        product.getName(), newPrice, alert.getTargetPrice(), alert.getUser().getEmail());
            }
        }
    }

    /**
     * Periyodik olarak fiyat kontrolü (her 5 dakikada bir)
     */
    @Scheduled(fixedRate = 300000) // 5 dakika
    public void checkPriceAlerts() {
        List<PriceAlert> alerts = priceAlertRepository.findAlertsBelowTargetPrice();
        
        for (PriceAlert alert : alerts) {
            alert.setNotified(true);
            alert.setNotifiedAt(LocalDateTime.now());
            priceAlertRepository.save(alert);
            
            log.info("🔔 Periyodik kontrol - Fiyat bildirimi: {} - {} TL (hedef: {} TL)", 
                    alert.getProduct().getName(), 
                    alert.getProduct().getPrice(), 
                    alert.getTargetPrice());
        }
    }

    /**
     * Ürünün fiyat geçmişini getir
     */
    public List<PriceHistory> getPriceHistory(Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new RuntimeException("Ürün bulunamadı: " + productId));
        
        return priceHistoryRepository.findByProductOrderByChangedAtDesc(product);
    }

    /**
     * Son 24 saatteki fiyat düşüşlerini getir
     */
    public List<PriceHistory> getRecentPriceDrops() {
        return priceHistoryRepository.findRecentPriceDrops(LocalDateTime.now().minusHours(24));
    }

    private PriceAlertDTO convertToDTO(PriceAlert alert) {
        Product product = alert.getProduct();
        return new PriceAlertDTO(
                alert.getId(),
                product.getId(),
                product.getName(),
                product.getImageUrl(),
                alert.getTargetPrice(),
                alert.getOriginalPrice(),
                product.getPrice(),
                alert.getActive(),
                alert.getNotified(),
                alert.getCreatedAt(),
                alert.getNotifiedAt()
        );
    }
}
