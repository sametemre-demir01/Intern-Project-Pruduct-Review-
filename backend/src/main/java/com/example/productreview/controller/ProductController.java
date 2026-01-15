package com.example.productreview.controller;

import com.example.productreview.dto.ProductDTO;
import com.example.productreview.dto.ReviewDTO;
import com.example.productreview.service.ProductService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/products")
@CrossOrigin(origins = "*")
public class ProductController {
    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    @GetMapping
    public Page<ProductDTO> getAllProducts(
            @RequestParam(required = false) String category,
            @PageableDefault(size = 20) Pageable pageable) {
        return productService.getAllProducts(category, pageable);
    }

    /**
     * Gelişmiş filtreleme ve sıralama ile ürün listesi
     * Örnek: /api/products/filter?minPrice=100&maxPrice=500&minRating=4&sortBy=price&sortDir=asc
     */
    @GetMapping("/filter")
    public Page<ProductDTO> getProductsWithFilters(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Double minPrice,
            @RequestParam(required = false) Double maxPrice,
            @RequestParam(required = false) Double minRating,
            @RequestParam(required = false, defaultValue = "id") String sortBy,
            @RequestParam(required = false, defaultValue = "asc") String sortDir,
            @PageableDefault(size = 20) Pageable pageable) {
        return productService.getProductsWithFilters(category, minPrice, maxPrice, minRating, sortBy, sortDir, pageable);
    }

    /**
     * Ürün karşılaştırma - maksimum 4 ürün
     * Örnek: /api/products/compare?ids=1,2,3
     */
    @GetMapping("/compare")
    public List<ProductDTO> compareProducts(@RequestParam List<Long> ids) {
        return productService.compareProducts(ids);
    }

    @GetMapping("/{id}")
    public ProductDTO getProductById(@PathVariable Long id) {
        return productService.getProductDTOById(id);
    }

    @GetMapping("/{id}/reviews")
    public Page<ReviewDTO> getReviewsByProductId(
            @PathVariable Long id,
            @RequestParam(required = false) Integer rating,
            @PageableDefault(size = 10, sort = "createdAt") Pageable pageable) {
        return productService.getReviewsByProductId(id, rating, pageable);
    }

    @PostMapping("/{id}/reviews")
    public ReviewDTO addReview(@PathVariable Long id, @Valid @RequestBody ReviewDTO reviewDTO) {
        return productService.addReview(id, reviewDTO);
    }

    @PutMapping("/reviews/{reviewId}/helpful")
    public ReviewDTO markReviewAsHelpful(@PathVariable Long reviewId) {
        return productService.markReviewAsHelpful(reviewId);
    }
}
