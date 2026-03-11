package com.nckh.yte.service;

import com.nckh.yte.dto.AuthResponse;
import com.nckh.yte.dto.LoginRequest;
import com.nckh.yte.dto.RegisterRequest;
import com.nckh.yte.entity.User;
import com.nckh.yte.repository.UserRepository;
import com.nckh.yte.security.JwtUtil;
import com.nckh.yte.security.UserDetailsImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthResponse login(LoginRequest req) {

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        req.getUsername(),
                        req.getPassword()
                )
        );

        UserDetailsImpl principal = (UserDetailsImpl) authentication.getPrincipal();

        String token = jwtUtil.generateToken(principal.getUsername());

        return new AuthResponse(
                token,
                principal.getUsername(),
                principal.getFullName()
        );
    }

    public void register(RegisterRequest req) {

        User user = new User();

        user.setUsername(req.getUsername());
        user.setPassword(passwordEncoder.encode(req.getPassword()));
        user.setFullName(req.getFullName());

        userRepository.save(user);
    }
}
