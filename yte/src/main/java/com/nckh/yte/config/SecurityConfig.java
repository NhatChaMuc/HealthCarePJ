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
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/api/auth/login", "/auth/login").permitAll()
                .requestMatchers("/api/auth/register", "/auth/register").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()

                // ✅ FIX Ánh xạ kép và hasAuthority
                .requestMatchers("/api/ai/**", "/ai/**").hasAnyAuthority("ADMIN", "DOCTOR", "NURSE", "PATIENT")
                .requestMatchers("/api/admin/**", "/admin/**").hasAuthority("ADMIN") 
                .requestMatchers("/api/doctor/**", "/doctor/**").hasAnyAuthority("DOCTOR", "ADMIN") 
                .requestMatchers("/api/nurse/**", "/nurse/**").hasAnyAuthority("NURSE", "ADMIN") 
                .requestMatchers(HttpMethod.GET, "/api/patients/**", "/patients/**").hasAnyAuthority("ADMIN", "DOCTOR", "NURSE")
                .requestMatchers(HttpMethod.POST, "/api/patients/**", "/patients/**").hasAuthority("ADMIN")
                .requestMatchers(HttpMethod.PUT, "/api/patients/**", "/patients/**").hasAuthority("ADMIN")
                .requestMatchers(HttpMethod.DELETE, "/api/patients/**", "/patients/**").hasAuthority("ADMIN")
                .requestMatchers(HttpMethod.GET, "/api/appointments/**", "/appointments/**").hasAnyAuthority("ADMIN", "DOCTOR", "NURSE", "PATIENT")
                .requestMatchers(HttpMethod.POST, "/api/appointments/auto-schedule", "/appointments/auto-schedule").hasAnyAuthority("PATIENT", "DOCTOR")
                .requestMatchers("/api/appointments/**", "/appointments/**").hasAnyAuthority("ADMIN", "DOCTOR", "NURSE")
                .requestMatchers("/api/info/**", "/info/**").hasAnyAuthority("ADMIN", "DOCTOR", "NURSE", "PATIENT")
                .requestMatchers("/api/user/**", "/user/**").authenticated() // Thêm UserController
                
                .anyRequest().authenticated()
            )

            .sessionManagement(sess -> sess.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        System.out.println("✅ SecurityConfig loaded (FINAL PATH FIX)");
        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}