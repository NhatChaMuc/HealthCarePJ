package com.nckh.yte.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins(
                                // 🌐 Vercel app (công khai)
                                "https://health-care-pj.vercel.app",
                                "http://health-care-pj.vercel.app",

                                // ☁️ Render backend
                                "https://healthcarepj.onrender.com",
                                "http://healthcarepj.onrender.com",

                                // 💻 Localhost dev
                                "http://localhost:8080",
                                "http://localhost:8081",
                                "http://127.0.0.1:8080",
                                "http://127.0.0.1:8081",

                                // 📱 Android emulator & LAN
                                "http://10.0.2.2:8081",
                                "http://192.168.1.10:8081",   // ⚠️ thay IP theo máy thật của cậu
                                "http://192.168.0.100:8081"
                        )
                        .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                        .allowedHeaders("*")
                        .exposedHeaders("Authorization")
                        .allowCredentials(false);
            }
        };
    }
}
