# Giai đoạn 1: Build ứng dụng (dùng Maven và eclipse-temurin 17)
FROM maven:3.8.5-eclipse-temurin-17 AS build

# Đặt thư mục làm việc
WORKDIR /app

# Copy file pom.xml và tải dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy toàn bộ source code
COPY src ./src

# Build ra file .jar
RUN mvn package -DskipTests

# ---

# Giai đoạn 2: Chạy ứng dụng (dùng ảnh eclipse-temurin JRE chuẩn)
# HÃY DÙNG DÒNG NÀY (Không có -slim)
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy file .jar đã build từ giai đoạn 1
COPY --from=build /app/target/yte-gemini-doctor-0.0.1-SNAPSHOT.jar app.jar

# Render yêu cầu chạy trên một port động (biến $PORT)
CMD ["java", "-jar", "app.jar", "--server.port=${PORT}"]