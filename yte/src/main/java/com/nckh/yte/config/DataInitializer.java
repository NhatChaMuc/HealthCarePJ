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

import java.util.Set;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    @Bean
    CommandLineRunner initDatabase(
            RoleRepository roleRepo,
            UserRepository userRepo,
            PasswordEncoder encoder) {
        
        return args -> {
            // 1) Đảm bảo các role (KHÔNG có prefix ROLE_) tồn tại
            Role adminRole = roleRepo.findByName("ADMIN").orElseGet(() -> 
                roleRepo.save(new Role(null, "ADMIN"))
            );
            roleRepo.findByName("DOCTOR").orElseGet(() -> 
                roleRepo.save(new Role(null, "DOCTOR"))
            );
            roleRepo.findByName("NURSE").orElseGet(() -> 
                roleRepo.save(new Role(null, "NURSE"))
            );
            roleRepo.findByName("PATIENT").orElseGet(() -> 
                roleRepo.save(new Role(null, "PATIENT"))
            );

            // 2) Tạo User Admin mặc định nếu nó chưa tồn tại
            if (!userRepo.existsByUsername("admin")) {
                User u = new User();
                u.setUsername("admin");
                u.setPassword(encoder.encode("admin123")); 
                u.setFullName("System Administrator");
                u.setEnabled(true);
                u.setRole(adminRole); 
                
                userRepo.save(u);
                System.out.println(">>>>>>>>>> ĐÃ TẠO USER ADMIN MẶC ĐỊNH <<<<<<<<<<");
            }
        };
    }
}