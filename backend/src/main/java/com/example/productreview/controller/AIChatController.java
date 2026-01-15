package com.example.productreview.controller;

import com.example.productreview.service.AISummaryService;
import com.example.productreview.service.ProductService;
import com.example.productreview.dto.ProductDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@CrossOrigin(origins = "*")
public class AIChatController {
    
    private final AISummaryService aiSummaryService;
    private final ProductService productService;

    public AIChatController(AISummaryService aiSummaryService, ProductService productService) {
        this.aiSummaryService = aiSummaryService;
        this.productService = productService;
    }

    /**
     * Genel AI Chat - ürün bağlamı olmadan
     * POST /api/ai/chat
     * Body: { "message": "Hangi telefonu almalıyım?" }
     */
    @PostMapping("/chat")
    public ResponseEntity<Map<String, String>> chat(@RequestBody Map<String, String> request) {
        String message = request.get("message");
        if (message == null || message.trim().isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Mesaj boş olamaz"));
        }
        
        String response = aiSummaryService.chat(message, null);
        return ResponseEntity.ok(Map.of("response", response));
    }

    /**
     * Ürün hakkında AI Chat
     * POST /api/ai/chat/product/{productId}
     * Body: { "message": "Bu ürün su geçirmez mi?" }
     */
    @PostMapping("/chat/product/{productId}")
    public ResponseEntity<Map<String, String>> chatAboutProduct(
            @PathVariable Long productId,
            @RequestBody Map<String, String> request) {
        String message = request.get("message");
        if (message == null || message.trim().isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Mesaj boş olamaz"));
        }
        
        try {
            // Ürün bilgisini al
            ProductDTO product = productService.getProductDTOById(productId);
            
            // Ürün bağlamını oluştur
            String productContext = String.format(
                    "Ürün: %s | Kategori: %s | Fiyat: %.2f TL | Ortalama Puan: %.1f/5 (%d yorum) | Açıklama: %s",
                    product.getName(),
                    product.getCategory(),
                    product.getPrice(),
                    product.getAverageRating(),
                    product.getReviewCount(),
                    product.getDescription()
            );
            
            // AI özeti varsa ekle
            if (product.getAiSummary() != null) {
                productContext += " | Yorum Özeti: " + product.getAiSummary();
            }
            
            String response = aiSummaryService.chat(message, productContext);
            return ResponseEntity.ok(Map.of(
                    "response", response,
                    "productName", product.getName()
            ));
            
        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Ürün bulunamadı: " + productId));
        }
    }

    /**
     * AI Ürün Karşılaştırma Analizi
     * POST /api/ai/compare
     * Body: { "productIds": [1, 2, 3] }
     */
    @PostMapping("/compare")
    public ResponseEntity<Map<String, Object>> compareWithAI(@RequestBody Map<String, Object> request) {
        @SuppressWarnings("unchecked")
        java.util.List<Integer> productIdInts = (java.util.List<Integer>) request.get("productIds");
        
        if (productIdInts == null || productIdInts.size() < 2) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "En az 2 ürün ID'si gerekli"));
        }
        
        java.util.List<Long> productIds = productIdInts.stream()
                .map(Integer::longValue)
                .collect(java.util.stream.Collectors.toList());
        
        // Ürünleri al
        java.util.List<ProductDTO> products = productService.compareProducts(productIds);
        
        if (products.size() < 2) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Karşılaştırma için en az 2 geçerli ürün gerekli"));
        }
        
        // Karşılaştırma bağlamı oluştur
        StringBuilder context = new StringBuilder("Karşılaştırılacak ürünler:\n");
        for (ProductDTO p : products) {
            context.append(String.format(
                    "- %s: %.2f TL, %.1f/5 puan (%d yorum), %s\n",
                    p.getName(), p.getPrice(), p.getAverageRating(), 
                    p.getReviewCount(), p.getDescription()
            ));
        }
        
        String prompt = "Bu ürünleri karşılaştır ve hangisinin hangi kullanım senaryosu için daha uygun olduğunu belirt.";
        String analysis = aiSummaryService.chat(prompt, context.toString());
        
        return ResponseEntity.ok(Map.of(
                "products", products,
                "analysis", analysis
        ));
    }
}
