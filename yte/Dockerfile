# Giai đoạn 1: Build ứng dụng (dùng Maven và Java 17)
# (Nếu dự án của bạn dùng Java 11, hãy đổi "17" thành "11")
FROM maven:3.8.5-openjdk-17 AS build

# Đặt thư mục làm việc
WORKDIR /app

# Copy file pom.xml và tải dependencies (để tận dụng cache)
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy toàn bộ source code
COPY src ./src

# Build ra file .jar
# (Thay 'yte-0.0.1-SNAPSHOT.jar' nếu tên file của bạn khác)
RUN mvn package -DskipTests

# ---

# Giai đoạn 2: Chạy ứng dụng (dùng ảnh JRE nhỏ gọn)
FROM openjdk:17-jre-slim

WORKDIR /app

# Copy file .jar đã build từ giai đoạn 1
COPY --from=build /app/target/yte-0.0.1-SNAPSHOT.jar app.jar

# Render yêu cầu chạy trên một port động (biến $PORT)
# Lệnh này sẽ chạy ứng dụng VÀ nhận port từ Render
CMD ["java", "-jar", "app.jar", "--server.port=${PORT}"]