package com.nckh.yte.entity;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
public class Nurse {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String fullName;

    private String username;

    private String password;

}
