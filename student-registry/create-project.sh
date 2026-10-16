#!/usr/bin/env bash
set -e

# === student-registry: генератор проекта ===
# Создаёт полное дерево Spring Boot проекта для лабораторной работы.

ROOT="$(pwd)"
SRC="$ROOT/src/main/java/ru/rvip/studentregistry"
RES="$ROOT/src/main/resources"
CHG="$RES/db/changelog"
CHG_A="$CHG/changes"

mkdir -p "$SRC/config" "$SRC/controller" "$SRC/dto" "$SRC/entity" \
         "$SRC/exception" "$SRC/repository" "$SRC/service"
mkdir -p "$CHG_A"

# ---------- pom.xml ----------
cat > "$ROOT/pom.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.3.5</version>
        <relativePath/>
    </parent>

    <groupId>ru.rvip</groupId>
    <artifactId>student-registry</artifactId>
    <version>1.0.0</version>
    <name>student-registry</name>
    <description>Учёт студентов по специальностям (лабораторная работа 1)</description>

    <properties>
        <java.version>17</java.version>
        <springdoc.version>2.6.0</springdoc.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.liquibase</groupId>
            <artifactId>liquibase-core</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>${springdoc.version}</version>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <finalName>student-registry</finalName>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

# ---------- .gitignore ----------
cat > "$ROOT/.gitignore" <<'EOF'
.env
target/
.idea/
*.iml
.vscode/
*.log
EOF

# ---------- .env ----------
cat > "$ROOT/.env" <<'EOF'
POSTGRES_DB=student_registry
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
EOF

# ---------- Dockerfile ----------
cat > "$ROOT/Dockerfile" <<'EOF'
FROM maven:3.9.9-eclipse-temurin-17 AS build

WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre

WORKDIR /app

COPY --from=build /app/target/student-registry.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
EOF

# ---------- docker-compose.yml ----------
cat > "$ROOT/docker-compose.yml" <<'EOF'
services:

  postgres:
    image: postgres:16
    container_name: student-registry-postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "5433:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 10

  app:
    build: .
    container_name: student-registry-app
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: docker
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

volumes:
  postgres_data:
EOF

# ---------- application.yml ----------
cat > "$RES/application.yml" <<'EOF'
spring:
  application:
    name: student-registry

  datasource:
    url: jdbc:postgresql://localhost:5433/student_registry
    username: postgres
    password: postgres
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: true
    open-in-view: false

  liquibase:
    enabled: true
    change-log: classpath:db/changelog/db.changelog-master.yaml

server:
  port: 8080

springdoc:
  swagger-ui:
    path: /swagger-ui.html
EOF

# ---------- application-docker.yml ----------
cat > "$RES/application-docker.yml" <<'EOF'
spring:
  datasource:
    url: jdbc:postgresql://postgres:5432/student_registry
    username: ${POSTGRES_USER}
    password: ${POSTGRES_PASSWORD}
EOF

# ---------- Liquibase master ----------
cat > "$CHG/db.changelog-master.yaml" <<'EOF'
databaseChangeLog:
  - include:
      file: db/changelog/changes/001-create-student-table.yaml
EOF

# ---------- Liquibase changeset ----------
cat > "$CHG_A/001-create-student-table.yaml" <<'EOF'
databaseChangeLog:
  - changeSet:
      id: 001-create-student-table
      author: alhimek17
      changes:
        - createTable:
            tableName: student
            remarks: Учёт студентов по специальностям
            columns:
              - column:
                  name: id
                  type: BIGSERIAL
                  autoIncrement: true
                  constraints:
                    primaryKey: true
                    primaryKeyName: pk_student
                    nullable: false

              - column:
                  name: full_name
                  type: VARCHAR(255)
                  constraints:
                    nullable: false

              - column:
                  name: specialty
                  type: VARCHAR(255)
                  constraints:
                    nullable: false

              - column:
                  name: status
                  type: VARCHAR(20)
                  defaultValue: ACTIVE
                  constraints:
                    nullable: false

              - column:
                  name: enrolled_at
                  type: TIMESTAMP
                  constraints:
                    nullable: false

              - column:
                  name: expelled_at
                  type: TIMESTAMP
                  constraints:
                    nullable: true

        - sql:
            sql: >
              ALTER TABLE student
              ADD CONSTRAINT chk_student_status
              CHECK (status IN ('ACTIVE', 'EXPELLED'));

        - sql:
            sql: >
              ALTER TABLE student
              ADD CONSTRAINT chk_student_expulsion
              CHECK (
                (status = 'ACTIVE' AND expelled_at IS NULL)
                OR
                (status = 'EXPELLED' AND expelled_at IS NOT NULL)
              );
EOF

# ---------- Java: Application ----------
cat > "$SRC/StudentRegistryApplication.java" <<'EOF'
package ru.rvip.studentregistry;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Точка входа приложения «Учёт студентов по специальностям».
 */
@SpringBootApplication
public class StudentRegistryApplication {

    public static void main(String[] args) {
        SpringApplication.run(StudentRegistryApplication.class, args);
    }
}
EOF

# ---------- Java: Entity ----------
cat > "$SRC/entity/Student.java" <<'EOF'
package ru.rvip.studentregistry.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

/**
 * Студент. Единственная бизнес-сущность в базе.
 */
@Entity
@Table(name = "student")
public class Student {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(nullable = false)
    private String specialty;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private StudentStatus status = StudentStatus.ACTIVE;

    @Column(name = "enrolled_at", nullable = false)
    private LocalDateTime enrolledAt;

    @Column(name = "expelled_at")
    private LocalDateTime expelledAt;

    public Student() {
    }

    @PrePersist
    public void prePersist() {
        if (enrolledAt == null) {
            enrolledAt = LocalDateTime.now();
        }
        if (status == null) {
            status = StudentStatus.ACTIVE;
        }
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getSpecialty() {
        return specialty;
    }

    public void setSpecialty(String specialty) {
        this.specialty = specialty;
    }

    public StudentStatus getStatus() {
        return status;
    }

    public void setStatus(StudentStatus status) {
        this.status = status;
    }

    public LocalDateTime getEnrolledAt() {
        return enrolledAt;
    }

    public void setEnrolledAt(LocalDateTime enrolledAt) {
        this.enrolledAt = enrolledAt;
    }

    public LocalDateTime getExpelledAt() {
        return expelledAt;
    }

    public void setExpelledAt(LocalDateTime expelledAt) {
        this.expelledAt = expelledAt;
    }

    /** Статус студента. */
    public enum StudentStatus {
        ACTIVE,
        EXPELLED
    }
}
EOF

# ---------- Java: DTO Enroll ----------
cat > "$SRC/dto/EnrollStudentRequest.java" <<'EOF'
package ru.rvip.studentregistry.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Запрос на приём студента на специальность. */
public record EnrollStudentRequest(

    @NotBlank(message = "ФИО не должно быть пустым")
    @Size(max = 255, message = "ФИО не должно превышать 255 символов")
    String fullName,

    @NotBlank(message = "Специальность не должна быть пустой")
    @Size(max = 255, message = "Специальность не должна превышать 255 символов")
    String specialty
) {}
EOF

# ---------- Java: DTO Transfer ----------
cat > "$SRC/dto/TransferStudentRequest.java" <<'EOF'
package ru.rvip.studentregistry.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Запрос на перевод студента на другую специальность. */
public record TransferStudentRequest(

    @NotBlank(message = "Новая специальность обязательна")
    @Size(max = 255, message = "Название специальности слишком длинное")
    String specialty
) {}
EOF

# ---------- Java: DTO Expel ----------
cat > "$SRC/dto/ExpelStudentRequest.java" <<'EOF'
package ru.rvip.studentregistry.dto;

import jakarta.validation.constraints.Size;

/** Запрос на отчисление студента. Причина не сохраняется в БД. */
public record ExpelStudentRequest(

    @Size(max = 1000, message = "Причина слишком длинная")
    String reason
) {}
EOF

# ---------- Java: DTO StudentResponse ----------
cat > "$SRC/dto/StudentResponse.java" <<'EOF'
package ru.rvip.studentregistry.dto;

import ru.rvip.studentregistry.entity.Student;

import java.time.LocalDateTime;

/** DTO ответа по студенту. */
public record StudentResponse(
    Long id,
    String fullName,
    String specialty,
    String status,
    LocalDateTime enrolledAt,
    LocalDateTime expelledAt
) {
    public static StudentResponse from(Student student) {
        return new StudentResponse(
            student.getId(),
            student.getFullName(),
            student.getSpecialty(),
            student.getStatus().name(),
            student.getEnrolledAt(),
            student.getExpelledAt()
        );
    }
}
EOF

# ---------- Java: DTO ReportResponse ----------
cat > "$SRC/dto/ReportResponse.java" <<'EOF'
package ru.rvip.studentregistry.dto;

import java.util.List;

/** Отчёт по специальностям. */
public record ReportResponse(
    long totalActive,
    long totalExpelled,
    List<SpecialtyStatistics> specialties
) {
    /** Статистика по одной специальности. */
    public record SpecialtyStatistics(
        String specialty,
        long active,
        long expelled
    ) {}
}
EOF

# ---------- Java: Repository ----------
cat > "$SRC/repository/StudentRepository.java" <<'EOF'
package ru.rvip.studentregistry.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import ru.rvip.studentregistry.entity.Student;
import ru.rvip.studentregistry.entity.Student.StudentStatus;

import java.util.List;

/** Репозиторий студентов. */
public interface StudentRepository extends JpaRepository<Student, Long> {

    /**
     * Агрегированная статистика: по каждой специальности — сколько
     * активных и сколько отчисленных.
     */
    @Query("""
        SELECT s.specialty,
               SUM(CASE WHEN s.status = :active THEN 1L ELSE 0L END),
               SUM(CASE WHEN s.status = :expelled THEN 1L ELSE 0L END)
        FROM Student s
        GROUP BY s.specialty
        ORDER BY s.specialty
        """)
    List<Object[]> getSpecialtyStatistics(
        @Param("active") StudentStatus active,
        @Param("expelled") StudentStatus expelled
    );

    long countByStatus(StudentStatus status);
}
EOF

# ---------- Java: Exceptions ----------
cat > "$SRC/exception/ResourceNotFoundException.java" <<'EOF'
package ru.rvip.studentregistry.exception;

/** Ресурс не найден (404). */
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}
EOF

cat > "$SRC/exception/BadRequestException.java" <<'EOF'
package ru.rvip.studentregistry.exception;

/** Некорректный бизнес-запрос (400). */
public class BadRequestException extends RuntimeException {
    public BadRequestException(String message) {
        super(message);
    }
}
EOF

cat > "$SRC/exception/GlobalExceptionHandler.java" <<'EOF'
package ru.rvip.studentregistry.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.Map;

/** Единая обработка ошибок REST-слоя. */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private Map<String, Object> body(String message, int status) {
        return Map.of(
            "timestamp", LocalDateTime.now().toString(),
            "status", status,
            "error", message
        );
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFound(
            ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(body(ex.getMessage(), 404));
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<Map<String, Object>> handleBadRequest(
            BadRequestException ex) {
        return ResponseEntity.badRequest()
            .body(body(ex.getMessage(), 400));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(
            MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
            .map(e -> e.getField() + ": " + e.getDefaultMessage())
            .findFirst()
            .orElse("Некорректные данные");
        return ResponseEntity.badRequest().body(body(message, 400));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleUnreadable(
            HttpMessageNotReadableException ex) {
        return ResponseEntity.badRequest()
            .body(body("Некорректный формат JSON", 400));
    }
}
EOF

# ---------- Java: Service ----------
cat > "$SRC/service/StudentService.java" <<'EOF'
package ru.rvip.studentregistry.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.rvip.studentregistry.dto.*;
import ru.rvip.studentregistry.entity.Student;
import ru.rvip.studentregistry.entity.Student.StudentStatus;
import ru.rvip.studentregistry.exception.BadRequestException;
import ru.rvip.studentregistry.exception.ResourceNotFoundException;
import ru.rvip.studentregistry.repository.StudentRepository;

import java.time.LocalDateTime;
import java.util.List;

/** Бизнес-логика учёта студентов. */
@Service
public class StudentService {

    private final StudentRepository repository;

    public StudentService(StudentRepository repository) {
        this.repository = repository;
    }

    /** Принять студента на специальность. */
    @Transactional
    public StudentResponse enroll(EnrollStudentRequest request) {
        Student student = new Student();
        student.setFullName(request.fullName().trim());
        student.setSpecialty(request.specialty().trim());
        student.setStatus(StudentStatus.ACTIVE);
        student.setEnrolledAt(LocalDateTime.now());
        return StudentResponse.from(repository.save(student));
    }

    /** Получить всех студентов. */
    @Transactional(readOnly = true)
    public List<StudentResponse> findAll() {
        return repository.findAll().stream()
            .map(StudentResponse::from)
            .toList();
    }

    /** Получить студента по id. */
    @Transactional(readOnly = true)
    public StudentResponse findById(Long id) {
        return StudentResponse.from(getStudent(id));
    }

    /** Отчислить за неуспеваемость. */
    @Transactional
    public StudentResponse expel(Long id, ExpelStudentRequest request) {
        Student student = getStudent(id);

        if (student.getStatus() == StudentStatus.EXPELLED) {
            throw new BadRequestException("Студент уже отчислен");
        }

        student.setStatus(StudentStatus.EXPELLED);
        student.setExpelledAt(LocalDateTime.now());
        return StudentResponse.from(repository.save(student));
    }

    /** Перевести на другую специальность. */
    @Transactional
    public StudentResponse transfer(Long id, TransferStudentRequest request) {
        Student student = getStudent(id);

        if (student.getStatus() != StudentStatus.ACTIVE) {
            throw new BadRequestException("Нельзя перевести отчисленного студента");
        }

        String newSpecialty = request.specialty().trim();

        if (student.getSpecialty().equalsIgnoreCase(newSpecialty)) {
            throw new BadRequestException("Студент уже обучается на этой специальности");
        }

        student.setSpecialty(newSpecialty);
        return StudentResponse.from(repository.save(student));
    }

    /** Удалить запись о студенте. */
    @Transactional
    public void delete(Long id) {
        Student student = getStudent(id);
        repository.delete(student);
    }

    /** Отчёт по специальностям. */
    @Transactional(readOnly = true)
    public ReportResponse getReport() {
        List<ReportResponse.SpecialtyStatistics> statistics =
            repository.getSpecialtyStatistics(
                StudentStatus.ACTIVE,
                StudentStatus.EXPELLED
            ).stream().map(row ->
                new ReportResponse.SpecialtyStatistics(
                    (String) row[0],
                    ((Number) row[1]).longValue(),
                    ((Number) row[2]).longValue()
                )
            ).toList();

        return new ReportResponse(
            repository.countByStatus(StudentStatus.ACTIVE),
            repository.countByStatus(StudentStatus.EXPELLED),
            statistics
        );
    }

    private Student getStudent(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException(
                "Студент с id=" + id + " не найден"));
    }
}
EOF

# ---------- Java: Controllers ----------
cat > "$SRC/controller/StudentController.java" <<'EOF'
package ru.rvip.studentregistry.controller;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import ru.rvip.studentregistry.dto.*;
import ru.rvip.studentregistry.service.StudentService;

import java.util.List;

/** REST-контроллер операций со студентами. */
@RestController
@RequestMapping("/api/students")
public class StudentController {

    private final StudentService service;

    public StudentController(StudentService service) {
        this.service = service;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StudentResponse enroll(@Valid @RequestBody EnrollStudentRequest request) {
        return service.enroll(request);
    }

    @GetMapping
    public List<StudentResponse> findAll() {
        return service.findAll();
    }

    @GetMapping("/{id}")
    public StudentResponse findById(@PathVariable Long id) {
        return service.findById(id);
    }

    @PostMapping("/{id}/expel")
    public StudentResponse expel(@PathVariable Long id,
                                 @Valid @RequestBody ExpelStudentRequest request) {
        return service.expel(id, request);
    }

    @PostMapping("/{id}/transfer")
    public StudentResponse transfer(@PathVariable Long id,
                                    @Valid @RequestBody TransferStudentRequest request) {
        return service.transfer(id, request);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long id) {
        service.delete(id);
    }
}
EOF

cat > "$SRC/controller/ReportController.java" <<'EOF'
package ru.rvip.studentregistry.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.rvip.studentregistry.dto.ReportResponse;
import ru.rvip.studentregistry.service.StudentService;

/** REST-контроллер отчётов. */
@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final StudentService service;

    public ReportController(StudentService service) {
        this.service = service;
    }

    @GetMapping("/specialties")
    public ReportResponse getSpecialtyReport() {
        return service.getReport();
    }
}
EOF

# ---------- Java: OpenAPI config ----------
cat > "$SRC/config/OpenApiConfig.java" <<'EOF'
package ru.rvip.studentregistry.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Конфигурация Swagger / OpenAPI. */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI studentRegistryOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Student Registry API")
                .version("1.0.0")
                .description("API для учёта студентов, переводов, отчислений "
                    + "и отчётов по специальностям."));
    }
}
EOF

# ---------- README ----------
cat > "$ROOT/README.md" <<'EOF'
# Student Registry — учёт студентов по специальностям

Лабораторная работа 1. Spring Boot + PostgreSQL + Liquibase + Docker + Swagger.
В базе — ровно одна бизнес-таблица `student`.

## Стек

- Java 17, Spring Boot 3.3.5, Maven
- Spring Web, Spring Data JPA, Validation
- PostgreSQL 16
- Liquibase (YAML)
- springdoc-openapi (Swagger UI)
- Docker, Docker Compose

## Структура
