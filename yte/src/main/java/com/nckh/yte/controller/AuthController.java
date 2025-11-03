package com.nckh.yte.controller;

import com.nckh.yte.dto.ApiResponse;
import com.nckh.yte.dto.LoginRequest;
import com.nckh.yte.dto.RegisterRequest;
import com.nckh.yte.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
// ✅ FIX: Sửa đường dẫn để khớp với Log (cả /api/auth và /auth)
@RequestMapping({"/api/auth", "/auth"}) 
@CrossOrigin(origins = "*", allowedHeaders = "*")
@RequiredArgsConstructor
public class AuthController {
    private final AuthService service;

   @PostMapping("/register")
   public ResponseEntity<?> register(@RequestBody RegisterRequest req) {
        var id = service.register(req);
        return ResponseEntity.ok(new ApiResponse("Registered successfully", id));
    }


    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        // On successful authentication return the AuthResponse directly.
        // The front–end expects the token, fullName and role fields at the top
        // level of the JSON response rather than nested under a "data" key.
        return ResponseEntity.ok(service.login(req));
    }
}