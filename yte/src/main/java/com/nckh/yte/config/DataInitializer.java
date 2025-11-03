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

import java.util.Set; // ⚠️ Đảm bảo bạn đã import Set

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    @Bean
    CommandLineRunner init(RoleRepository roleRepo,
                           UserRepository userRepo,
                           PasswordEncoder encoder) {
        return args -> {
            
            // 1) Đảm bảo các role (với prefix ROLE_) tồn tại
            Role adminRole = roleRepo.findByName("ROLE_ADMIN").orElseGet(() -> 
                roleRepo.save(new Role(null, "ROLE_ADMIN"))
            );
            roleRepo.findByName("ROLE_DOCTOR").orElseGet(() -> 
                roleRepo.save(new Role(null, "ROLE_DOCTOR"))
            );
            roleRepo.findByName("ROLE_NURSE").orElseGet(() -> 
                roleRepo.save(new Role(null, "ROLE_NURSE"))
            );
            roleRepo.findByName("ROLE_PATIENT").orElseGet(() -> 
                roleRepo.save(new Role(null, "ROLE_PATIENT"))
            );

            // 2) Nếu chưa có bất kỳ user nào mang role ADMIN -> auto tạo
            // (Code kiểm tra của bạn rất hay, nhưng chúng ta có thể làm đơn giản hơn
            //  bằng cách chỉ kiểm tra sự tồn tại của 'admin')

            if (!userRepo.existsByUsername("admin")) {
                // Tạo mới tài khoản admin mặc định
                User u = new User();
                u.setUsername("admin");
                u.setPassword(encoder.encode("admin123")); // đổi sau khi đăng nhập
                u.setFullName("System Administrator");
                u.setEnabled(true);
                u.setRole(adminRole); // Gán role đã có prefix
                
                userRepo.save(u);
                System.out.println(">>>>>>>>>> ĐÃ TẠO USER ADMIN (ROLE_ADMIN) MẶC ĐỊNH <<<<<<<<<<");
            }
        };
    }
}