package com.nckh.yte.service;

import com.nckh.yte.dto.*;
import com.nckh.yte.security.UserDetailsImpl;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    public AuthResponse login(UserDetailsImpl principal, String token){

        return new AuthResponse(
                token,
                principal.getUsername(),
                principal.getFullName()
        );

    }

    public void register(RegisterRequest req){

        String username = req.getUsername();
        String password = req.getPassword();
        String fullName = req.getFullName();

        // xử lý lưu DB
    }

}
