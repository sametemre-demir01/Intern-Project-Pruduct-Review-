package com.example.productreview.service;

import com.example.productreview.model.Review;
import io.github.sashirestela.openai.SimpleOpenAI;
import io.github.sashirestela.openai.domain.chat.ChatRequest;
import io.github.sashirestela.openai.domain.chat.ChatMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * AI-powered review summary service using ChatGPT
 * Supports both real OpenAI API and mock mode for testing
 */
@Service
public class AISummaryService {
    
    private static final Logger log = LoggerFactory.getLogger(AISummaryService.class);
    
    private final String apiKey;
    private final String model;
    private final Integer maxTokens;
    private final boolean testMode;
    private final SimpleOpenAI openAI;

    public AISummaryService(
            @Value("${openai.api.key:test-key}") String apiKey,
            @Value("${openai.model:gpt-4o-mini}") String model,
            @Value("${openai.max.tokens:500}") Integer maxTokens) {
        this.apiKey = apiKey;
        this.model = model;
        this.maxTokens = maxTokens;
        // TEST MODE: If API key is not set or is test key, use mock responses
        this.testMode = apiKey == null || apiKey.isEmpty() || 
                        apiKey.equals("test-key") || 
                        apiKey.equals("your-api-key-here") ||
                        !apiKey.startsWith("sk-");
        
        if (testMode) {
            log.warn("⚠️ AISummaryService running in TEST MODE - using mock summaries");
            this.openAI = null;
        } else {
            log.info("✅ AISummaryService initialized with real OpenAI API key");
            this.openAI = SimpleOpenAI.builder()
                    .apiKey(apiKey)
                    .build();
        }
    }
    
    /**
     * Chat ile AI'a soru sor (ürün hakkında veya genel)
     */
    public String chat(String userMessage, String productContext) {
        if (testMode) {
            return generateMockChatResponse(userMessage, productContext);
        }

        try {
            String systemPrompt = productContext != null && !productContext.isEmpty()
                    ? "Sen yardımcı bir ürün asistanısın. Ürün bilgisi: " + productContext
                    : "Sen yardımcı bir e-ticaret asistanısın.";
            
            var chatRequest = ChatRequest.builder()
                    .model(model)
                    .message(ChatMessage.SystemMessage.of(systemPrompt))
                    .message(ChatMessage.UserMessage.of(userMessage))
                    .maxTokens(maxTokens)
                    .temperature(0.7)
                    .build();

            var futureChat = openAI.chatCompletions().create(chatRequest);
            var chatResponse = futureChat.join();
            
            String response = chatResponse.firstContent();
            log.info("🤖 AI Chat response: {} chars", response.length());
            return response;
            
        } catch (Exception e) {
            log.error("OpenAI Chat Error: ", e);
            return "Üzgünüm, şu anda yanıt veremiyorum. Lütfen daha sonra tekrar deneyin.";
        }
    }
    
    private String generateMockChatResponse(String userMessage, String productContext) {
        String lowerMessage = userMessage.toLowerCase();
        
        if (lowerMessage.contains("fiyat") || lowerMessage.contains("price")) {
            return "Bu ürün, kategorisindeki benzer ürünlerle karşılaştırıldığında rekabetçi bir fiyata sahip. Kalite ve özellikler göz önüne alındığında iyi bir değer sunuyor.";
        } else if (lowerMessage.contains("karşılaştır") || lowerMessage.contains("compare")) {
            // Dinamik karşılaştırma yanıtı oluştur
            if (productContext != null && productContext.contains("Karşılaştırılacak ürünler:")) {
                return generateDynamicComparisonResponse(productContext);
            }
            return "Bu ürün, benzer ürünlerle karşılaştırıldığında öne çıkan özelliklere sahip. Özellikle kalite ve performans açısından avantajlı.";
        } else if (lowerMessage.contains("tavsiye") || lowerMessage.contains("recommend")) {
            return "Müşteri yorumlarına göre bu ürün yüksek memnuniyet oranına sahip. Özellikle günlük kullanım için tavsiye edilebilir.";
        } else if (lowerMessage.contains("özellik") || lowerMessage.contains("feature")) {
            return "Bu ürünün temel özellikleri arasında kaliteli malzeme, modern tasarım ve kullanım kolaylığı yer alıyor.";
        } else if (lowerMessage.contains("garanti") || lowerMessage.contains("warranty")) {
            return "Ürün garantisi ve iade politikası hakkında detaylı bilgi için satıcıyla iletişime geçmenizi öneririm.";
        } else {
            return "Bu ürün hakkında müşteri yorumlarına göre genel olarak olumlu geri bildirimler var. Size başka nasıl yardımcı olabilirim?";
        }
    }
    
    public String callOpenAI(String prompt) {
        if (testMode) {
            return "AI Test Mode: This product looks great based on the initial specs! (Mock Response)";
        }

        try {
            var chatRequest = ChatRequest.builder()
                    .model(model)
                    .message(ChatMessage.UserMessage.of(prompt))
                    .maxTokens(maxTokens)
                    .temperature(0.7)
                    .build();

            var futureChat = openAI.chatCompletions().create(chatRequest);
            var chatResponse = futureChat.join();
            
            return chatResponse.firstContent();
        } catch (Exception e) {
            log.error("OpenAI Error: ", e);
            return "I'm sorry, I cannot answer right now. Please try again later.";
        }
    }
    /**
     * Generate AI summary for product reviews
     * Result is cached for 1 hour based on productId
     * 
     * @param productId Product ID
     * @param productName Product name for context
     * @param reviews List of reviews to summarize
     * @return AI-generated summary or null if error/no reviews
     */
    @Cacheable(value = "aiSummaries", key = "#productId")
    public String generateReviewSummary(Long productId, String productName, List<Review> reviews) {
        // Generate summary if there is at least 1 review
        if (reviews == null || reviews.isEmpty()) {
            log.info("No reviews for product {}, skipping summary", productId);
            return null;
        }

        try {
            // TEST MODE: Return mock summary
            if (testMode) {
                String mockSummary = generateMockSummary(productName, reviews);
                log.info("📝 Generated MOCK summary for product {}: {} chars", productId, mockSummary.length());
                return mockSummary;
            }
            
            // REAL MODE: Call OpenAI API
            String prompt = buildReviewSummaryPrompt(productName, reviews);
            
            var chatRequest = ChatRequest.builder()
                    .model(model)
                    .message(ChatMessage.SystemMessage.of(
                            "Sen bir ürün inceleme analisti olarak görev yapıyorsun. " +
                            "Verilen yorumları analiz ederek kısa ve öz bir özet oluştur. " +
                            "Türkçe ve İngilizce karışık yazabilirsin."))
                    .message(ChatMessage.UserMessage.of(prompt))
                    .maxTokens(maxTokens)
                    .temperature(0.7)
                    .build();

            var futureChat = openAI.chatCompletions().create(chatRequest);
            var chatResponse = futureChat.join();
            
            String summary = chatResponse.firstContent();
            log.info("✅ Generated REAL AI summary for product {}: {} chars", productId, summary.length());
            return summary;
            
        } catch (Exception e) {
            log.error("Error generating AI summary for product {}: {}", productId, e.getMessage(), e);
            // Fallback to mock summary on error
            return generateMockSummary(productName, reviews);
        }
    }
    
    /**
     * Build prompt for review summary
     */
    private String buildReviewSummaryPrompt(String productName, List<Review> reviews) {
        StringBuilder prompt = new StringBuilder();
        prompt.append("Ürün: ").append(productName).append("\n\n");
        prompt.append("Müşteri Yorumları:\n");
        
        for (int i = 0; i < Math.min(reviews.size(), 10); i++) {
            Review r = reviews.get(i);
            prompt.append(String.format("- [%d/5 yıldız] %s: %s\n", 
                    r.getRating(), r.getReviewerName(), r.getComment()));
        }
        
        prompt.append("\nBu yorumları analiz ederek 2-3 cümlelik bir özet oluştur. ");
        prompt.append("Genel memnuniyet durumunu, öne çıkan olumlu ve olumsuz yönleri belirt.");
        
        return prompt.toString();
    }

    /**
     * Generate a mock summary based on review statistics
     * This simulates what ChatGPT would return
     */
    private String generateMockSummary(String productName, List<Review> reviews) {
        // Calculate statistics
        double avgRating = reviews.stream()
                .mapToInt(Review::getRating)
                .average()
                .orElse(0.0);
        
        long positiveReviews = reviews.stream()
                .filter(r -> r.getRating() >= 4)
                .count();
        
        long negativeReviews = reviews.stream()
                .filter(r -> r.getRating() <= 2)
                .count();
        
        double positivePercentage = (positiveReviews * 100.0) / reviews.size();
        
        // Generate sentiment
        String sentiment;
        if (avgRating >= 4.0) {
            sentiment = "overwhelmingly positive";
        } else if (avgRating >= 3.5) {
            sentiment = "generally positive";
        } else if (avgRating >= 2.5) {
            sentiment = "mixed";
        } else {
            sentiment = "generally negative";
        }
        
        // Get common themes from actual reviews
        String commonPraise = extractCommonThemes(reviews, true);
        String commonComplaints = extractCommonThemes(reviews, false);
        
        // Build mock summary
        StringBuilder summary = new StringBuilder();
        summary.append(String.format("Based on %d customer reviews, the overall sentiment is %s with an average rating of %.1f stars. ", 
                reviews.size(), sentiment, avgRating));
        
        if (positivePercentage >= 70) {
            summary.append(String.format("%.0f%% of customers gave 4-5 star ratings. ", positivePercentage));
            summary.append(commonPraise);
        } else if (positivePercentage >= 40) {
            summary.append("Opinions are mixed. ");
            summary.append(commonPraise);
            summary.append(" However, ");
            summary.append(commonComplaints);
        } else {
            summary.append(commonComplaints);
        }
        
        summary.append(" Consider these factors when making your purchase decision.");
        
        return summary.toString();
    }
    
    /**
     * Extract common themes from reviews
     */
    private String extractCommonThemes(List<Review> reviews, boolean positive) {
        // Filter reviews by rating
        List<Review> filtered = reviews.stream()
                .filter(r -> positive ? r.getRating() >= 4 : r.getRating() <= 2)
                .collect(Collectors.toList());
        
        if (filtered.isEmpty()) {
            return "";
        }
        
        // Get most common words/phrases from comments
        List<String> comments = filtered.stream()
                .map(Review::getComment)
                .map(String::toLowerCase)
                .collect(Collectors.toList());
        
        // Simple theme extraction based on common words
        if (positive) {
            boolean mentionsQuality = comments.stream().anyMatch(c -> c.contains("quality") || c.contains("great") || c.contains("excellent"));
            boolean mentionsPerformance = comments.stream().anyMatch(c -> c.contains("performance") || c.contains("fast") || c.contains("speed"));
            boolean mentionsDesign = comments.stream().anyMatch(c -> c.contains("design") || c.contains("look") || c.contains("beautiful"));
            
            if (mentionsQuality && mentionsPerformance) {
                return "Customers praise the excellent quality and strong performance. ";
            } else if (mentionsQuality && mentionsDesign) {
                return "Users appreciate the high quality and attractive design. ";
            } else if (mentionsQuality) {
                return "The product quality receives consistent praise. ";
            } else if (mentionsPerformance) {
                return "Performance is highlighted as a key strength. ";
            } else if (mentionsDesign) {
                return "The design and aesthetics are well-received. ";
            } else {
                return "Most customers report positive experiences. ";
            }
        } else {
            boolean mentionsPrice = comments.stream().anyMatch(c -> c.contains("expensive") || c.contains("price") || c.contains("cost"));
            boolean mentionsBattery = comments.stream().anyMatch(c -> c.contains("battery"));
            boolean mentionsBugs = comments.stream().anyMatch(c -> c.contains("bug") || c.contains("issue") || c.contains("problem"));
            
            if (mentionsPrice && mentionsBattery) {
                return "Some customers feel the price is high and mention battery concerns. ";
            } else if (mentionsPrice) {
                return "The main complaint centers around the price point. ";
            } else if (mentionsBattery) {
                return "Battery life is a common concern among users. ";
            } else if (mentionsBugs) {
                return "Several users report technical issues or bugs. ";
            } else {
                return "Some customers have expressed concerns. ";
            }
        }
    }
    
    /**
     * Generate dynamic comparison response based on product context
     */
    private String generateDynamicComparisonResponse(String productContext) {
        try {
            // Parse product information from context
            String[] lines = productContext.split("\n");
            java.util.List<String> productNames = new java.util.ArrayList<>();
            java.util.List<Double> prices = new java.util.ArrayList<>();
            java.util.List<Double> ratings = new java.util.ArrayList<>();
            java.util.List<Integer> reviewCounts = new java.util.ArrayList<>();
            
            for (String line : lines) {
                if (line.startsWith("- ")) {
                    // Parse: "- Product Name: 100.00 TL, 4.5/5 puan (10 yorum), description"
                    String productInfo = line.substring(2);
                    
                    // Find the first ": " to separate name from details
                    int colonIndex = productInfo.indexOf(": ");
                    if (colonIndex > 0) {
                        String name = productInfo.substring(0, colonIndex).trim();
                        String details = productInfo.substring(colonIndex + 2).trim();
                        
                        productNames.add(name);
                        
                        // Extract price: "100.00 TL"
                        java.util.regex.Pattern pricePattern = java.util.regex.Pattern.compile("([0-9]+(?:\\.[0-9]+)?)\\s*TL");
                        java.util.regex.Matcher priceMatcher = pricePattern.matcher(details);
                        if (priceMatcher.find()) {
                            prices.add(Double.parseDouble(priceMatcher.group(1)));
                        } else {
                            prices.add(0.0); // Default if not found
                        }
                        
                        // Extract rating: "4.5/5"
                        java.util.regex.Pattern ratingPattern = java.util.regex.Pattern.compile("([0-9]+(?:\\.[0-9]+)?)/5");
                        java.util.regex.Matcher ratingMatcher = ratingPattern.matcher(details);
                        if (ratingMatcher.find()) {
                            ratings.add(Double.parseDouble(ratingMatcher.group(1)));
                        } else {
                            ratings.add(0.0); // Default if not found
                        }
                        
                        // Extract review count: "(10 yorum)"
                        java.util.regex.Pattern reviewPattern = java.util.regex.Pattern.compile("\\((\\d+)\\s*yorum\\)");
                        java.util.regex.Matcher reviewMatcher = reviewPattern.matcher(details);
                        if (reviewMatcher.find()) {
                            reviewCounts.add(Integer.parseInt(reviewMatcher.group(1)));
                        } else {
                            reviewCounts.add(0); // Default if not found
                        }
                    }
                }
            }
            
            if (productNames.size() < 2) {
                return "Bu ürünler karşılaştırıldığında, her birinin kendine özgü avantajları bulunuyor. Detaylı karar için özellik listelerini inceleyebilirsiniz.";
            }
            
            // Find best value metrics
            double maxRating = ratings.stream().mapToDouble(Double::doubleValue).max().orElse(0);
            double minPrice = prices.stream().mapToDouble(Double::doubleValue).min().orElse(0);
            int maxReviews = reviewCounts.stream().mapToInt(Integer::intValue).max().orElse(0);
            
            StringBuilder response = new StringBuilder();
            response.append("Bu ").append(productNames.size()).append(" ürünü karşılaştırdığımda:\n\n");
            
            // Price analysis
            if (minPrice > 0) {
                response.append("💰 Fiyat açısından: ");
                for (int i = 0; i < productNames.size(); i++) {
                    if (prices.get(i) == minPrice) {
                        response.append("\"").append(productNames.get(i)).append("\" en uygun fiyatlı seçenek (").append(minPrice).append(" TL). ");
                        break;
                    }
                }
                response.append("\n");
            }
            
            // Rating analysis
            if (maxRating > 0) {
                response.append("⭐ Kalite açısından: ");
                for (int i = 0; i < productNames.size(); i++) {
                    if (ratings.get(i) == maxRating) {
                        response.append("\"").append(productNames.get(i)).append("\" (").append(maxRating).append("/5 puan) en yüksek puan almış. ");
                        break;
                    }
                }
                response.append("\n");
            }
            
            // Review count analysis
            if (maxReviews > 0) {
                response.append("📊 Yorum sayısı açısından: ");
                for (int i = 0; i < productNames.size(); i++) {
                    if (reviewCounts.get(i) == maxReviews) {
                        response.append("\"").append(productNames.get(i)).append("\" (").append(maxReviews).append(" yorum) en çok değerlendirilmiş. ");
                        break;
                    }
                }
                response.append("\n");
            }
            
            // Recommendation based on data
            response.append("\n📋 Öneri: ");
            boolean hasHighRating = maxRating >= 4.5;
            boolean hasManyReviews = maxReviews >= 10;
            boolean hasLowPrice = minPrice > 0 && minPrice < 1000; // Assuming reasonable price threshold
            
            if (hasHighRating && hasManyReviews) {
                response.append("Hem yüksek puan hem de çok sayıda yorum alan ürünler güvenilir seçenekler. ");
                if (hasLowPrice) {
                    response.append("Ayrıca uygun fiyatlı alternatifler de mevcut.");
                } else {
                    response.append("Kalite odaklıysanız yüksek puanlı ürünleri tercih edebilirsiniz.");
                }
            } else if (hasHighRating) {
                response.append("Kalite odaklıysanız yüksek puanlı ürünleri tercih edebilirsiniz.");
            } else if (hasManyReviews) {
                response.append("Çok sayıda yorum alan ürünler daha güvenilir olabilir.");
            } else {
                response.append("Tüm seçenekler dikkate alınmaya değer, kullanım amacınıza göre karar verin.");
            }
            
            return response.toString();
            
        } catch (Exception e) {
            log.warn("Error generating dynamic comparison response: {}", e.getMessage());
            return "Bu ürünler karşılaştırıldığında, her birinin kendine özgü avantajları bulunuyor. Detaylı karar için özellik listelerini inceleyebilirsiniz.";
        }
    }
}
