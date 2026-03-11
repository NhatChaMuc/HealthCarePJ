package com.nckh.yte.service;

import com.nckh.yte.dto.LoginRequest;
import com.nckh.yte.security.UserDetailsImpl;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    public String login(LoginRequest req){

        String username = req.getUsername();
        String password = req.getPassword();

        // xử lý auth
        return "OK";
    }

    public String getUser(UserDetailsImpl principal){

        String username = principal.getUsername();
        String fullname = principal.getFullName();

        return username + " - " + fullname;
    }

}
