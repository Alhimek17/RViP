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
