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
