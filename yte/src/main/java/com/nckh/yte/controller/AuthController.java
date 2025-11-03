package com.nckh.yte.controller;

import com.nckh.yte.dto.ApiResponse;
import com.nckh.yte.dto.LoginRequest;
import com.nckh.yte.dto.RegisterRequest;
import com.nckh.yte.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
// ✅ FIX: Ánh xạ tới cả /api/auth và /auth
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
        return ResponseEntity.ok(service.login(req));
    }
}