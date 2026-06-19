FROM eclipse-temurin:21-jre-alpine
LABEL authors="Galdino"

WORKDIR /app

COPY target/DHKeyManager-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]