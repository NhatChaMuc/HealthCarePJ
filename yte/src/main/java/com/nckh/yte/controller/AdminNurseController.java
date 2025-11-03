package com.nckh.yte.controller;

import com.nckh.yte.entity.Nurse;
import com.nckh.yte.service.NurseService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Controller cho chức năng quản lý y tá.  
 */
@RestController
// ✅ FIX: Sửa đường dẫn để khớp với Log (cả /api/admin và /admin)
@RequestMapping({"/api/admin", "/admin"}) 
@CrossOrigin(origins = "*")
public record AdminNurseController(NurseService service) {

    record Req(String fullName, String username, String password) {}

    @PostMapping("/create-nurse")
    public ResponseEntity<?> createNurse(@RequestBody Req req) {
        try {
            Nurse nurse = service.create(req.fullName(), req.username(), req.password());
            return ResponseEntity.ok(Map.of(
                    "message", "Tạo y tá thành công!",
                    "id", nurse.getId(),
                    "fullName", nurse.getFullName(),
                    "username", nurse.getUsername()
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.status(409).body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("message", "Lỗi server khi tạo y tá: " + e.getMessage()));
        }
    }
}