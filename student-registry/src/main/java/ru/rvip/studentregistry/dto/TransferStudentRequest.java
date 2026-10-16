package ru.rvip.studentregistry.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Запрос на перевод студента на другую специальность. */
public record TransferStudentRequest(

    @NotBlank(message = "Новая специальность обязательна")
    @Size(max = 255, message = "Название специальности слишком длинное")
    String specialty
) {}
