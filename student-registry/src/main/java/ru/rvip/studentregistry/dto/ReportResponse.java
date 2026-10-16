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
