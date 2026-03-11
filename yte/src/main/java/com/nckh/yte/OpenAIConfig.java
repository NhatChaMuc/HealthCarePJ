package com.nckh.yte;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "ai.openai")
public class OpenAIConfig {
    private String model;
    private String apikey;
    private String baseurl;
    private String organization;
    private String project;

    // ===== THÊM GETTER THỦ CÔNG =====
    public String getModel() { return model; }
    public String getApikey() { return apikey; }
    public String getBaseurl() { return baseurl; }
    public String getOrganization() { return organization; }
    public String getProject() { return project; }

    // Nếu cần setter (cho cấu hình) cũng nên thêm:
    public void setModel(String model) { this.model = model; }
    public void setApikey(String apikey) { this.apikey = apikey; }
    public void setBaseurl(String baseurl) { this.baseurl = baseurl; }
    public void setOrganization(String organization) { this.organization = organization; }
    public void setProject(String project) { this.project = project; }
}
