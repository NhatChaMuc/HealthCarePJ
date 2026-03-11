@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "ai.openai")
public class OpenAIConfig {

    private String model;
    private String apikey;
    private String baseurl;
}
