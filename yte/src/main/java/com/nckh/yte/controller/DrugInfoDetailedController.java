package com.nckh.yte.controller;

import com.nckh.yte.OpenAIConfig;
import com.nckh.yte.entity.Information;
import com.nckh.yte.repository.InformationRepository;
import lombok.RequiredArgsConstructor;
import org.json.JSONArray;
import org.json.JSONObject;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

import java.net.URI;
import java.util.*;

@RestController
// ✅ FIX MAPPING: Ánh xạ tới cả /api/ai và /ai để giải quyết lỗi 404
@RequestMapping({"/api/ai", "/ai"})
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DrugInfoDetailedController {

    private final OpenAIConfig openAIConfig;
    private final RestTemplate restTemplate;
    private final InformationRepository informationRepository;

    @PostMapping("/drug-info-full")
    public ResponseEntity<Object> getDrugInfoFull(@RequestBody Map<String, String> body) {
        String drugName = body != null ? body.get("drug") : null;
        if (drugName == null || drugName.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Missing 'drug' field!"));
        }
        
        final String trimmedDrugName = drugName.trim();

        // 1. KIỂM TRA CACHE TRƯỚC
        try {
            Optional<Information> cached = informationRepository.findByName(trimmedDrugName);
            if (cached.isPresent()) {
                String cachedJson = cached.get().getResponseData();
                Map<String, Object> cachedResponse = new JSONObject(cachedJson).toMap();
                if (cachedResponse.containsKey("items")) {
                     return ResponseEntity.ok(cachedResponse);
                }
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi đọc cache: " + e.getMessage());
        }

        // 2. GỌI THẲNG GPT (OpenAI)
        try {
            Map<String, Object> aiResponse = callGptForDrugInfo(trimmedDrugName);
            Map<String, Object> responseMap;

            // Kiểm tra xem AI có trả về lỗi "không tìm thấy" không
            if (aiResponse.containsKey("error")) {
                responseMap = Map.of(
                        "items", Collections.emptyList(),
                        "message", aiResponse.get("error").toString()
                );
                saveToCache(trimmedDrugName, responseMap);
                return ResponseEntity.ok(responseMap);
            }
            
            // Gói nó vào list 'items'
            List<Map<String, Object>> items = new ArrayList<>();
            items.add(aiResponse);
            
            responseMap = Map.of("items", items);

            // 3. LƯU KẾT QUẢ MỚI VÀO CACHE
            saveToCache(trimmedDrugName, responseMap);
            return ResponseEntity.ok(responseMap);

        } catch (HttpStatusCodeException ex) {
            // Lỗi mạng khi gọi OpenAI
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(Map.of(
                    "error", "Lỗi khi gọi AI (GPT): " + ex.getStatusCode(),
                    "detail", ex.getResponseBodyAsString()
            ));
        } catch (Exception e) {
            // Lỗi Java (ví dụ: Lỗi parse JSON từ AI)
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Lỗi máy chủ nội bộ (GPT): " + e.getMessage()));
        }
    }

    private void saveToCache(String drugName, Map<String, Object> responseMap) {
        try {
            String responseJson = new JSONObject(responseMap).toString();
            
            Information newCacheEntry = new Information();
            newCacheEntry.setName(drugName); 
            newCacheEntry.setResponseData(responseJson);
            
            informationRepository.save(newCacheEntry);
        } catch (Exception e) {
            System.err.println("Lỗi khi lưu cache: " + e.getMessage());
        }
    }

    private Map<String, Object> callGptForDrugInfo(String drugName) {
        URI uri = URI.create(trimTrailingSlash(openAIConfig.getBaseurl()) + "/chat/completions");
        // ... (Giữ nguyên logic gọi API GPT) ...
        String userPrompt = "Tôi cần tìm thông tin về thuốc: \"" + drugName + "\"\n\n" +
                "Tên thuốc này có thể viết sai, hoặc là tên tiếng Việt (ví dụ: 'thuốc cảm'), hoặc là tên biệt dược. Hãy cố gắng tìm ra thuốc đúng nhất.\n\n" +
                "Nếu không thể tìm thấy bất kỳ thông tin nào về thuốc này, hãy trả về JSON:\n" +
                "{ \"error\": \"Không thể tìm thấy thông tin cho thuốc '" + drugName + "'.\" }\n\n" +
                "Nếu tìm thấy, hãy trả về một đối tượng JSON duy nhất với cấu trúc sau (giữ nguyên key tiếng Việt, chỉ điền thông tin nếu tìm thấy):\n" +
                "{\n" +
                "  \"Tên thuốc\": \"[Tên thuốc đúng, chuẩn]\",\n" +
                "  \"Hãng sản xuất\": \"[Tên hãng sản xuất, nếu có]\",\n" +
                "  \"Tóm tắt bác sĩ\": \"[Tóm tắt chung về thuốc, khoảng 2-3 câu bằng tiếng Việt]\",\n" +
                "  \"Chỉ định / Công dụng\": \"[Nội dung chi tiết, dùng gạch đầu dòng •]\",\n" +
                "  \"Liều dùng\": \"[Nội dung chi tiết]\",\n" +
                "  \"Chống chỉ định\": \"[Nội dung chi tiết]\",\n" +
                "  \"Tác dụng phụ\": \"[Nội dung chi tiết]\",\n" +
                "  \"Thận trọng / Lưu ý\": \"[Nội dung chi tiết]\",\n" +
                "  \"Tương tác thuốc\": \"[Nội dung chi tiết]\"\n" +
                "}";
        
        JSONObject body = new JSONObject()
            .put("model", openAIConfig.getModel())
            .put("messages", new JSONArray()
                    .put(new JSONObject()
                            .put("role", "system")
                            .put("content", "Bạn là một dược sĩ AI chuyên nghiệp. Nhiệm vụ của bạn là cung cấp thông tin thuốc chi tiết, chính xác bằng tiếng Việt. Luôn luôn trả lời dưới dạng một đối tượng JSON duy nhất, không thêm bất kỳ giải thích nào bên ngoài JSON."))
                    .put(new JSONObject()
                            .put("role", "user")
                            .put("content", userPrompt)))
            .put("temperature", 0.2);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(openAIConfig.getApikey());
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));

        HttpEntity<String> req = new HttpEntity<>(body.toString(), headers);

        try {
            ResponseEntity<String> res = restTemplate.exchange(uri, HttpMethod.POST, req, String.class);
            if (!res.getStatusCode().is2xxSuccessful() || res.getBody() == null) {
                throw new RuntimeException("Không có phản hồi từ OpenAI");
            }

            JSONObject json = new JSONObject(res.getBody());
            JSONArray choices = json.optJSONArray("choices");
            if (choices == null || choices.isEmpty()) throw new RuntimeException("Không có dữ liệu (choices) từ OpenAI");
            
            JSONObject msg = choices.getJSONObject(0).optJSONObject("message");
            String content = msg != null ? msg.optString("content", "{}") : "{}";

            String cleanedJson = cleanGptJson(content);
            
            JSONObject drugJson = new JSONObject(cleanedJson);
            return drugJson.toMap();

        } catch (HttpStatusCodeException ex) {
            throw ex;
        } catch (Exception e) {
            throw new RuntimeException("Lỗi khi gọi hoặc phân tích (parse) phản hồi từ OpenAI: " + e.getMessage());
        }
    }

    private static String cleanGptJson(String s) {
        if (s == null) return "{}";
        String cleaned = s.trim();
        if (cleaned.startsWith("```json")) {
            cleaned = cleaned.substring(7);
        }
        if (cleaned.endsWith("```")) {
            cleaned = cleaned.substring(0, cleaned.length() - 3);
        }
        return cleaned.trim();
    }

    private static String trimTrailingSlash(String s) {
        if (s == null) return "";
        return s.endsWith("/") ? s.substring(0, s.length() - 1) : s;
    }
}