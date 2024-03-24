# Backend microservice Dockerfile

# Base image
FROM openjdk:11-jre

# Set working directory
WORKDIR /app

# Copy application JAR file
COPY target/*.jar app.jar

# Expose port (Port numarasını 8081 olarak değiştirin)
EXPOSE 8081

# Command to run the application
CMD ["java", "-jar", "app.jar"]
