package com.nckh.yte.service;

import com.nckh.yte.dto.LoginRequest;
import com.nckh.yte.dto.RegisterRequest;
import com.nckh.yte.entity.Role;
import com.nckh.yte.entity.User;
import com.nckh.yte.repository.RoleRepository;
import com.nckh.yte.repository.UserRepository;
import com.nckh.yte.security.UserDetailsImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.UUID;

@Service
@RequiredArgsConstructor  // thay vì @Service và không có constructor
public class AuthService {

    private final UserRepository userRepo;
    private final RoleRepository roleRepo;
    private final PasswordEncoder encoder;

    public UUID register(RegisterRequest req) {
        // 1. Kiểm tra username đã tồn tại chưa
        if (userRepo.existsByUsername(req.getUsername())) {
            throw new RuntimeException("Username đã được sử dụng");
        }

        // 2. Lấy role mặc định (PATIENT) – bạn có thể tuỳ chỉnh theo ý
        Role role = roleRepo.findByName("PATIENT")
                .orElseThrow(() -> new RuntimeException("Không tìm thấy role PATIENT"));

        // 3. Tạo user mới
        User user = new User();
        user.setUsername(req.getUsername());
        user.setPassword(encoder.encode(req.getPassword()));
        user.setFullName(req.getFullName());
        user.setEnabled(true);
        user.setRole(role);

        // 4. Lưu và trả về ID
        return userRepo.save(user).getId();
    }

    public String login(LoginRequest req){
        // Tạm thời để giả – sau này bạn sẽ xử lý authentication thật
        return "OK";
    }

    public String getUser(UserDetailsImpl principal){
        return principal.getUsername() + " - " + principal.getFullName();
    }
}
