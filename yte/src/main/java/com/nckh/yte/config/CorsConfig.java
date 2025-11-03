package com.nckh.yte.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.List;

@Configuration
public class CorsConfig {

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration cfg = new CorsConfiguration();

        // ⬇️ *** THAY ĐỔI DUY NHẤT Ở ĐÂY *** ⬇️
        cfg.setAllowedOriginPatterns(List.of(
                // Thêm URL Frontend production của bạn
                "https://health-care-pj.vercel.app",

                // Giữ lại các URL local để test
                "http://localhost:*",
                "http://127.0.0.1:*",
                "http://172.*.*.*:*",
                "http://192.168.*.*:*"
        ));
        // ⬆️ *** HẾT THAY ĐỔI *** ⬆️

        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("Origin", "Content-Type", "Accept", "Authorization"));
        cfg.setExposedHeaders(List.of("Authorization", "Content-Disposition"));
        cfg.setAllowCredentials(false); // (Giữ nguyên cài đặt của bạn)
        cfg.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", cfg); // Áp dụng cho mọi đường dẫn
        return source;
    }
}