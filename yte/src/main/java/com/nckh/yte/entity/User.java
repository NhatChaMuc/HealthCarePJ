package com.nckh.yte.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
public class User {

    @Id
    @GeneratedValue
    private UUID id;

    private String username;

    private String password;

    private String fullName;

    private boolean enabled;

    @ManyToOne
    private Role role;
}
