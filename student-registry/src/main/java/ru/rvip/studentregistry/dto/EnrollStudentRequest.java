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
