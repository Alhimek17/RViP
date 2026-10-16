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
