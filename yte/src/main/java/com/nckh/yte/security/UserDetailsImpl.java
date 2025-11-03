package com.nckh.yte.security;

import com.nckh.yte.entity.User;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.*;

@Getter
public class UserDetailsImpl implements UserDetails {
    private final UUID id;
    private final String username;
    private final String password;
    private final String fullName;
    private final boolean enabled;
    private final String roleName;
    private final Set<String> roles; // Dùng để check hasRole
    private final Collection<? extends GrantedAuthority> authorities; // Dùng để check hasAuthority

    public UserDetailsImpl(User u) {
        this.id = u.getId();
        this.username = u.getUsername();
        this.password = u.getPassword();
        this.fullName = u.getFullName();
        this.enabled = u.isEnabled();

        // DB chỉ chứa "ADMIN", "DOCTOR", "NURSE", "PATIENT"
        String dbRole = Optional.ofNullable(u.getRole())
                .map(r -> r.getName())
                .orElse("PATIENT");

        // ⚡️ authorities cần có prefix "ROLE_" cho Spring Security
        this.authorities = List.of(new SimpleGrantedAuthority("ROLE_" + dbRole));

        // Gửi ra FE vai trò không prefix
        this.roles = Set.of(dbRole);
        this.roleName = dbRole;
    }

    // ✅ FIX LỖI: Triển khai hàm hasAuthority để khắc phục lỗi Unimplemented
    @Override
    public boolean hasAuthority(String authorityName) {
        return this.authorities.stream()
                .anyMatch(a -> a.getAuthority().equalsIgnoreCase(authorityName));
    }
    
    // ✅ HÀM hasRole (Dùng cho code cũ của bạn)
    public boolean hasRole(String role) {
        return roles.contains(role);
    }

    // === CÁC HÀM BẮT BUỘC KHÁC (UserDetails) ===
    
    @Override public Collection<? extends GrantedAuthority> getAuthorities() { return authorities; }
    @Override public String getPassword() { return password; }
    @Override public String getUsername() { return username; }
    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return enabled; }

    public String getFullName() { return fullName; }
    public UUID getId() { return id; }
}