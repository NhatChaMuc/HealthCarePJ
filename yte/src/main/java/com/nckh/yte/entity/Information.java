package com.nckh.yte.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class Information {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String name;

    @Column(columnDefinition="TEXT")
    private String responseData;

    // ===== THÊM CÁC SETTER/GETTER THỦ CÔNG =====
    public void setName(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    public void setResponseData(String responseData) {
        this.responseData = responseData;
    }

    public String getResponseData() {
        return responseData;
    }
}
