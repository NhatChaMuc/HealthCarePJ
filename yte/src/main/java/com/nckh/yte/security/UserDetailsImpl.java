package com.nckh.yte.security;

import com.nckh.yte.entity.User; 
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import lombok.Getter;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.Set; // Thêm Set import

@Getter // Cần Lombok Getter
public class UserDetailsImpl implements UserDetails {
    // Khai báo các fields như trong code gốc của bạn
    private final UUID id;
    private final String username;
    private final String password;
    private final String fullName;
    private final boolean enabled;
    private final String roleName;
    private final Set<String> roles; 
    private final Collection<? extends GrantedAuthority> authorities;

    public UserDetailsImpl(User u) {
        this.id = u.getId();
        this.username = u.getUsername();
        this.password = u.getPassword();
        this.fullName = u.getFullName();
        this.enabled = u.isEnabled();

        String dbRole = (u.getRole() != null) ? u.getRole().getName() : "PATIENT";
        
        // Tạo Authorities
        this.authorities = List.of(new SimpleGrantedAuthority("ROLE_" + dbRole));

        // Khởi tạo các trường khác
        this.roles = Set.of(dbRole);
        this.roleName = dbRole;
    }

    // ✅ FIX: SỬA LỖI BIÊN DỊCH - Đảm bảo hàm này là @Override bắt buộc
    @Override 
    public Collection<? extends GrantedAuthority> getAuthorities() { 
        return this.authorities; 
    }

    // ✅ FIX: HÀM BỊ THIẾU (Đã triển khai để Controller gọi)
    public boolean hasAuthority(String authorityName) {
        return this.authorities.stream()
                .anyMatch(a -> a.getAuthority().equalsIgnoreCase(authorityName));
    }
    
    // ✅ HÀM hasRole (Dùng cho code cũ của bạn)
    public boolean hasRole(String roleName) {
        return this.roles.contains(roleName); // So sánh với role KHÔNG prefix
    }
    
    // === CÁC HÀM BẮT BUỘC KHÁC (UserDetails) ===
    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
}