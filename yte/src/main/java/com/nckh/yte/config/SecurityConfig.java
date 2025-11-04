package com.nckh.yte.config;

import com.nckh.yte.security.JwtAuthFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

/**
 * ⚙️ Cấu hình bảo mật chính cho hệ thống Y Tế AI
 * - JWT Stateless
 * - Phân quyền theo ROLE
 * - Cho phép alias cũ cho Flutter FE (/ai/... và /appointments/...)
 */
@Configuration
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // 🚫 Vô hiệu hoá CSRF, cho phép CORS
            .cors(cors -> {})
            .csrf(csrf -> csrf.disable())

            // ⚖️ Phân quyền truy cập
            .authorizeHttpRequests(auth -> auth

                // 🔓 Public endpoints
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/api/auth/**", "/auth/**").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()

                // 🧠 AI endpoints
                .requestMatchers("/api/ai/**", "/ai/**")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_DOCTOR", "ROLE_NURSE", "ROLE_PATIENT")

                // 🏥 Appointment APIs — hỗ trợ cả alias FE cũ
                .requestMatchers(HttpMethod.GET,
                        "/api/appointments/**",
                        "/appointments/**"      // ✅ alias cũ
                ).hasAnyAuthority("ROLE_ADMIN", "ROLE_DOCTOR", "ROLE_NURSE", "ROLE_PATIENT")

                .requestMatchers(HttpMethod.POST,
                        "/api/appointments/auto-schedule",
                        "/ai/auto-schedule"     // ✅ alias cũ
                ).hasAnyAuthority("ROLE_PATIENT", "ROLE_DOCTOR")

                // 👩‍⚕️ Patient APIs
                .requestMatchers(HttpMethod.GET, "/api/patients/**")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_DOCTOR", "ROLE_NURSE")
                .requestMatchers(HttpMethod.POST, "/api/patients/**")
                    .hasAuthority("ROLE_ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/patients/**")
                    .hasAuthority("ROLE_ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/patients/**")
                    .hasAuthority("ROLE_ADMIN")

                // ℹ️ Info APIs
                .requestMatchers("/api/info/**")
                    .hasAnyAuthority("ROLE_ADMIN", "ROLE_DOCTOR", "ROLE_NURSE", "ROLE_PATIENT")

                // 👤 User APIs
                .requestMatchers("/api/user/**").authenticated()

                // Các request khác cần xác thực
                .anyRequest().authenticated()
            )

            // 🪙 Cấu hình session stateless & JWT Filter
            .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        System.out.println("✅ SecurityConfig loaded with /ai/* and /appointments/* alias support");
        return http.build();
    }
}
