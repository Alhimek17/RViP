package ru.rvip.studentregistry.dto;

import jakarta.validation.constraints.Size;

/** Запрос на отчисление студента. Причина не сохраняется в БД. */
public record ExpelStudentRequest(

    @Size(max = 1000, message = "Причина слишком длинная")
    String reason
) {}
