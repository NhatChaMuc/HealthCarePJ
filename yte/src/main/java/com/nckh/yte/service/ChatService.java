package com.example.yte.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Service
@RequiredArgsConstructor
public class ChatService {

    @Value("${ai.openai.apikey}")
    private String openAiKey;

    @Value("${ai.openai.model}")
    private String model;

    private final RestTemplate restTemplate = new RestTemplate();

    public String askAI(String userMessage) {

        String url = "https://api.openai.com/v1/chat/completions";

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(openAiKey);
        headers.setContentType(MediaType.APPLICATION_JSON);

        Map<String, Object> body = new HashMap<>();
        body.put("model", model);

        List<Map<String, String>> messages = new ArrayList<>();

        Map<String, String> systemPrompt = new HashMap<>();
        systemPrompt.put("role", "system");
        systemPrompt.put("content",
                "Bạn là trợ lý AI trong hệ thống quản lý bệnh viện. " +
                "Nhiệm vụ của bạn là hỗ trợ bệnh nhân tra cứu thông tin thuốc, " +
                "hướng dẫn cơ bản về sức khỏe và giải thích thông tin y khoa một cách dễ hiểu.");

        Map<String, String> user = new HashMap<>();
        user.put("role", "user");
        user.put("content", userMessage);

        messages.add(systemPrompt);
        messages.add(user);

        body.put("messages", messages);

        HttpEntity<Map<String, Object>> request =
                new HttpEntity<>(body, headers);

        ResponseEntity<Map> response =
                restTemplate.postForEntity(url, request, Map.class);

        Map choice = (Map)((List)response.getBody().get("choices")).get(0);
        Map messageObj = (Map)choice.get("message");

        return messageObj.get("content").toString();
    }
}
