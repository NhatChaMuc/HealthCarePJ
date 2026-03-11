# Giai đoạn 1: Build ứng dụng
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copy pom.xml và tải TẤT CẢ dependencies + plugins
COPY pom.xml .
RUN mvn dependency:resolve dependency:resolve-plugins

# Copy toàn bộ source code
COPY src ./src

# Thêm "clean" để đảm bảo không bị dính class cũ lỗi
RUN mvn clean package -DskipTests

# ---

# Giai đoạn 2: Chạy ứng dụng
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy file .jar đã build
COPY --from=build /app/target/yte-gemini-doctor-0.0.1-SNAPSHOT.jar app.jar

CMD ["java", "-jar", "app.jar", "--server.port=${PORT}"]
