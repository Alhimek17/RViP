package ru.rvip.studentregistry.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Конфигурация Swagger / OpenAPI. */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI studentRegistryOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("Student Registry API")
                .version("1.0.0")
                .description("API для учёта студентов, переводов, отчислений "
                    + "и отчётов по специальностям."));
    }
}
