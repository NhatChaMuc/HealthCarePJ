package com.nckh.yte.controller;

import com.nckh.yte.entity.Appointment;
import com.nckh.yte.repository.DoctorRepository;
import com.nckh.yte.repository.NurseRepository;
import com.nckh.yte.repository.PatientRepository;
import com.nckh.yte.security.UserDetailsImpl;
import com.nckh.yte.service.AppointmentService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
@RequestMapping({"/api/appointments", "/appointments"})
public class AppointmentController {

    private final AppointmentService appointmentService;
    private final DoctorRepository doctorRepository;
    private final NurseRepository nurseRepository;
    private final PatientRepository patientRepository;

    @PostMapping("/auto-schedule") 
    public ResponseEntity<Appointment> autoSchedule(@RequestBody Map<String, Object> body) {
        if (body == null) return ResponseEntity.badRequest().build();
        // Logic auto-schedule...
        // Tạm thời trả về rỗng để tránh lỗi biên dịch nếu logic phức tạp bị thiếu
        return ResponseEntity.ok(null); 
    }

    @GetMapping("/me")
    public ResponseEntity<List<Appointment>> myAppointments(Authentication authentication) {
        UserDetailsImpl principal = (UserDetailsImpl) authentication.getPrincipal();

        // ✅ FIX 403: Sử dụng hàm hasAuthority MỚI được triển khai
        
        // Doctor
        if (principal.hasAuthority("ROLE_DOCTOR")) {
            var doctor = doctorRepository.findByUsername(principal.getUsername()).orElse(null);
            if (doctor == null) return ResponseEntity.ok(List.of());
            return ResponseEntity.ok(appointmentService.getAppointmentsForDoctor(doctor.getId()));
        }

        // Nurse
        else if (principal.hasAuthority("ROLE_NURSE")) {
            var nurse = nurseRepository.findByUsername(principal.getUsername()).orElse(null);
            if (nurse == null) return ResponseEntity.ok(List.of());
            return ResponseEntity.ok(appointmentService.getAppointmentsForNurse(nurse.getId()));
        }

        // Patient
        else if (principal.hasAuthority("ROLE_PATIENT")) {
            var patient = patientRepository.findByUser_Username(principal.getUsername()).orElse(null);
            if (patient == null) return ResponseEntity.ok(List.of());
            return ResponseEntity.ok(appointmentService.getAppointmentsForPatient(patient.getId()));
        }
        
        // Admin
        else if (principal.hasAuthority("ROLE_ADMIN")) {
            // Lỗi biên dịch: Gọi hàm đã FIX trong AppointmentService.java
            return ResponseEntity.ok(appointmentService.getAllAppointments()); 
        }

        return ResponseEntity.ok(List.of());
    }
}