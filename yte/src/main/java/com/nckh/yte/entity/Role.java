package com.nckh.yte.entity;

import jakarta.persistence.*;
import java.util.UUID;

@Entity
public class Role {

    @Id
    @GeneratedValue
    private UUID id;

    private String name;

    // Constructor mặc định (bắt buộc cho JPA)
    public Role() {
    }

    // Constructor đầy đủ tham số
    public Role(UUID id, String name) {
        this.id = id;
        this.name = name;
    }

    // Getter và Setter cho id
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    // Getter và Setter cho name
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
