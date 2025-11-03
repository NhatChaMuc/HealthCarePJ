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
import java.util.Set; 
import java.util.Optional; 

@Getter
public class UserDetailsImpl implements UserDetails {
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

        String dbRole = Optional.ofNullable(u.getRole())
                .map(r -> r.getName())
                .orElse("PATIENT");

        this.authorities = List.of(new SimpleGrantedAuthority("ROLE_" + dbRole));

        this.roles = Set.of(dbRole);
        this.roleName = dbRole;
    }

    // ✅ FIX: HÀM BỊ THIẾU
    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() { 
        return this.authorities; 
    }
    
    // ✅ HÀM CŨ: Dùng để kiểm tra trong Controller
    public boolean hasAuthority(String authorityName) {
        return this.authorities.stream()
                .anyMatch(a -> a.getAuthority().equalsIgnoreCase(authorityName));
    }

    @Override public String getPassword() { return password; }
    @Override public String getUsername() { return username; }
    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return enabled; } 
    public boolean hasRole(String roleName) { return this.roles.contains(roleName); }
}