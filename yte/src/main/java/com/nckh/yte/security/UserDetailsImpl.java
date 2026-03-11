package com.nckh.yte.security;

import com.nckh.yte.entity.User;
import lombok.AllArgsConstructor;
import lombok.Data;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.UUID; // Bổ sung import UUID

@Data
@AllArgsConstructor
public class UserDetailsImpl implements UserDetails {

    private UUID id; // Đã đổi từ Long sang UUID cho khớp với User entity
    private String username;
    private String password;
    private String fullName;

    private Collection<? extends GrantedAuthority> authorities;

    public static UserDetailsImpl build(User user) {
        return new UserDetailsImpl(
                user.getId(),
                user.getUsername(),
                user.getPassword(),
                user.getFullName(),
                null // Lưu ý: Chỗ này bạn có thể map Role của User thành GrantedAuthority sau
        );
    }

    // Tự định nghĩa thêm hàm hasAuthority để Controller sử dụng
    public boolean hasAuthority(String roleName) {
        if (authorities == null || authorities.isEmpty()) {
            return false;
        }
        return authorities.stream()
                .anyMatch(auth -> auth.getAuthority().equals(roleName));
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}
