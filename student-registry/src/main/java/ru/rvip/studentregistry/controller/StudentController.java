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
