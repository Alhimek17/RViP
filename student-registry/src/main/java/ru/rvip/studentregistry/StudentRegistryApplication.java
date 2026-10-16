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
