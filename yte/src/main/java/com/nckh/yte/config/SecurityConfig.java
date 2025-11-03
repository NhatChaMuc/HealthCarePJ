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
 * ⚙️ Cấu hình bảo mật chính của hệ thống (JWT + Roles)
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
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> {})
            .csrf(csrf -> csrf.disable())

            .authorizeHttpRequests(auth -> auth
                // ✅ Preflight (browser)
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                // 🔑 Public: Đăng nhập và Đăng ký (FIX: Ánh xạ kép)
                .requestMatchers("/api/auth/login", "/auth/login", "/api/auth/register", "/auth/register").permitAll()
                
                // ✅ Swagger
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()

                // ❌ TẤT CẢ API CẦN XÁC THỰC SỬ DỤNG hasAuthority("ROLE_...")
                // Ánh xạ kép và Authority đầy đủ
                .requestMatchers("/api/ai/**", "/ai/**").hasAnyAuthority("ROLE_ADMIN", "ROLE_DOCTOR", "ROLE_NURSE", "ROLE_PATIENT")
                .requestMatchers("/api/admin/**", "/admin/**").hasAuthority("ROLE_ADMIN") 
                .requestMatchers("/api/doctor/**", "/doctor/**").hasAnyAuthority("ROLE_DOCTOR", "ROLE_ADMIN") 
                .requestMatchers("/api/nurse/**", "/nurse/**").hasAnyAuthority("ROLE_NURSE", "ROLE_ADMIN") 
                
                // Patient APIs
                .requestMatchers(HttpMethod.GET, "/api/patients/**", "/patients/**").hasAnyAuthority("ROLE_ADMIN", "ROLE_DOCTOR", "ROLE_NURSE")
                .requestMatchers(HttpMethod.POST, "/api/patients/**", "/patients/**").hasAuthority("ROLE_ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/patients/**", "/patients/**").hasAuthority("ROLE_ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/patients/**", "/patients/**").hasAuthority("ROLE_ADMIN")

                // Appointment APIs
                .requestMatchers(HttpMethod.GET, "/api/appointments/**", "/appointments/**").hasAnyAuthority("ROLE_ADMIN", "ROLE_DOCTOR", "ROLE_NURSE", "ROLE_PATIENT")
                .requestMatchers(HttpMethod.POST, "/api/appointments/auto-schedule", "/appointments/auto-schedule").hasAnyAuthority("ROLE_PATIENT", "ROLE_DOCTOR")
                .requestMatchers("/api/appointments/**", "/appointments/**").hasAnyAuthority("ROLE_ADMIN", "ROLE_DOCTOR", "ROLE_NURSE")

                // Info APIs
                .requestMatchers("/api/info/**", "/info/**").hasAnyAuthority("ROLE_ADMIN", "ROLE_DOCTOR", "ROLE_NURSE", "ROLE_PATIENT")
                
                // User API
                .requestMatchers("/api/user/**", "/user/**").authenticated() // Thêm UserController
                
                // ✅ Mặc định: cần xác thực
                .anyRequest().authenticated()
            )

            // ⚙️ Stateless JWT
            .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

            // ⚙️ Thêm filter JWT vào chain
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        System.out.println("✅ SecurityConfig loaded (FINAL FIX: Consistent Roles)");
        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}