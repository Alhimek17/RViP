package ru.rvip.studentregistry.exception;

/** Некорректный бизнес-запрос (400). */
public class BadRequestException extends RuntimeException {
    public BadRequestException(String message) {
        super(message);
    }
}
