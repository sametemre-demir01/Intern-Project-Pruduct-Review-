package com.example.productreview.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * Ana sayfa controller'ı - API bilgilerini gösterir
 */
@RestController
public class HomeController {

    @GetMapping("/")
    public Map<String, Object> home() {
        Map<String, Object> response = new HashMap<>();
        response.put("name", "Product Review API");
        response.put("version", "1.0.0");
        response.put("status", "running");
        response.put("message", "Hoş geldiniz! 🎉");
        
        Map<String, String> endpoints = new HashMap<>();
        endpoints.put("products", "/api/products");
        endpoints.put("reviews", "/api/products/{id}/reviews");
        endpoints.put("auth_login", "/api/auth/login");
        endpoints.put("auth_register", "/api/auth/register");
        endpoints.put("ai_summary", "/api/ai/products/{id}/summary");
        endpoints.put("h2_console", "/h2-console");
        
        response.put("endpoints", endpoints);
        
        Map<String, String> users = new HashMap<>();
        users.put("admin", "admin@test.com / admin123");
        users.put("user", "user@test.com / user123");
        response.put("test_users", users);
        
        return response;
    }
}
