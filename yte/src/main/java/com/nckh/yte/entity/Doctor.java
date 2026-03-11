package com.nckh.yte.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

// VẪN GIỮ LOMBOK ĐỂ HỖ TRỢ, NHƯNG VẪN THÊM THỦ CÔNG
@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Doctor {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String fullName;
    private String username;

    // ===== THÊM GETTER & SETTER THỦ CÔNG =====
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
}
