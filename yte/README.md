
# Gemini Doctor Backend (Spring Boot)

This is a minimal Spring Boot backend that exposes a `/api/chat` endpoint and forwards requests to the Gemini (Generative Language) API.
It is configured as a "virtual doctor" assistant that returns guidance to patients in Vietnamese.
- Java 17
- Spring Boot 3.1.4
- Lombok (optional)

## How to run

1. Update `src/main/resources/application.yml` with your Gemini API key.
2. Build and run with Maven:
   ```bash
   mvn clean package
   mvn spring-boot:run
   ```
3. Test the endpoints:
   - `GET /api/chat/ping` -> health check
   - `POST /api/chat` -> JSON body `{ "message": "triệu chứng ..." }`

## Notes
- When using Flutter Web as the frontend, ensure CORS is allowed (this project enables CORS for all origins).
- The service sends a "system prompt" to Gemini to instruct it to behave as a medical advisor. The assistant is **not** a substitute for professional medical diagnosis.
