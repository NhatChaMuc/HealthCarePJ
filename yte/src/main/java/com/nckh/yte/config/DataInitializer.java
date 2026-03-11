package com.nckh.yte.config;

import com.nckh.yte.entity.Role;
import com.nckh.yte.entity.User;
import com.nckh.yte.repository.RoleRepository;
import com.nckh.yte.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    @Bean
    CommandLineRunner initDatabase(
            RoleRepository roleRepo,
            UserRepository userRepo,
            PasswordEncoder encoder) {
        
        return args -> {
            // 1) Đảm bảo các role (KHÔNG có prefix ROLE_) tồn tại trong DB
            // Lưu ý: Không dùng constructor có tham số để tránh lỗi Lombok
            Role adminRole = roleRepo.findByName("ADMIN").orElseGet(() -> {
                Role r = new Role();
                r.setName("ADMIN");
                return roleRepo.save(r);
            });

            roleRepo.findByName("DOCTOR").orElseGet(() -> {
                Role r = new Role();
                r.setName("DOCTOR");
                return roleRepo.save(r);
            });

            roleRepo.findByName("NURSE").orElseGet(() -> {
                Role r = new Role();
                r.setName("NURSE");
                return roleRepo.save(r);
            });

            roleRepo.findByName("PATIENT").orElseGet(() -> {
                Role r = new Role();
                r.setName("PATIENT");
                return roleRepo.save(r);
            });

            // 2) Tạo User Admin mặc định nếu nó chưa tồn tại
            if (!userRepo.existsByUsername("admin")) {
                User u = new User();
                u.setUsername("admin");
                u.setPassword(encoder.encode("admin123"));
                u.setFullName("System Administrator");
                u.setEnabled(true);
                u.setRole(adminRole); // Gán role ADMIN đã tạo ở trên
                
                userRepo.save(u);
                System.out.println(">>>>>>>>>> ĐÃ TẠO USER ADMIN MẶC ĐỊNH <<<<<<<<<<");
            }
        };
    }
}
