package com.nckh.yte;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
@ConfigurationProperties(prefix = "ai.gemini")
public class DrugApiConfig {

    private String model;
    private String apiKey;
    private String baseUrl;

    public String buildUrl() {
        return baseUrl + model + ":generateContent?key=" + apiKey;
    }

}
