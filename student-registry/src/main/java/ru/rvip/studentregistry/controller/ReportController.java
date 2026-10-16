package ru.rvip.studentregistry.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ru.rvip.studentregistry.dto.ReportResponse;
import ru.rvip.studentregistry.service.StudentService;

/** REST-контроллер отчётов. */
@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final StudentService service;

    public ReportController(StudentService service) {
        this.service = service;
    }

    @GetMapping("/specialties")
    public ReportResponse getSpecialtyReport() {
        return service.getReport();
    }
}
