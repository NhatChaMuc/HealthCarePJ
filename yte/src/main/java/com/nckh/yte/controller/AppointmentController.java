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
// ✅ FIX MAPPING: Ánh xạ tới cả /api/appointments và /appointments
@RequestMapping({"/api/appointments", "/appointments"})
public class AppointmentController {

    private final AppointmentService appointmentService;
    private final DoctorRepository doctorRepository;
    private final NurseRepository nurseRepository;
    private final PatientRepository patientRepository;

    // 🎯 Hàm này cần gọi đến: /appointments/auto-schedule (đã fix trong SecurityConfig)
    @PostMapping("/auto-schedule") 
    public ResponseEntity<Appointment> autoSchedule(@RequestBody Map<String, Object> body) {
        if (body == null) return ResponseEntity.badRequest().build();

        // ✅ BƯỚC 1: Trích xuất đối tượng patient
        String fullName = null;
        String email = null;
        String phone = null;
        String gender = null;
        Object patientObj = body.get("patient");
        
        if (patientObj instanceof Map<?, ?> patientMap) {
            fullName = patientMap.get("fullName") != null ? patientMap.get("fullName").toString() : null;
            email = patientMap.get("email") != null ? patientMap.get("email").toString() : null;
            phone = patientMap.get("phone") != null ? patientMap.get("phone").toString() : null;
            gender = patientMap.get("gender") != null ? patientMap.get("gender").toString() : null;
        }

        // ✅ BƯỚC 2: Trích xuất các trường khác
        String symptom = body.containsKey("symptom") ? (String) body.get("symptom") : null;
        Object dateObj = body.get("preferredDate");
        String preferredWindow = body.containsKey("preferredWindow") ? (String) body.get("preferredWindow") : null;
        
        if (dateObj == null || fullName == null) {
            return ResponseEntity.badRequest().build();
        }

        String dateStr = dateObj.toString();
        // FE gửi chuỗi ISO 8601 (2025-11-01T...)
        LocalDate preferredDate = LocalDate.parse(dateStr.substring(0, 10));

        // ✅ BƯỚC 3: Gọi service với đầy đủ thông tin
        Appointment appt = appointmentService.autoBook(
                fullName, email, phone, gender, 
                symptom, preferredDate, preferredWindow
        );
        return ResponseEntity.ok(appt);
    }

    // ✅ Sửa: Bỏ prefix /api/appointments/ vì nó đã ở @RequestMapping
    @GetMapping("/me")
    public ResponseEntity<List<Appointment>> myAppointments(Authentication authentication) {
        UserDetailsImpl principal = (UserDetailsImpl) authentication.getPrincipal();

        // Doctor
        if (principal.hasRole("DOCTOR")) {
            var doctor = doctorRepository.findByUsername(principal.getUsername()).orElse(null);
            if (doctor == null) return ResponseEntity.ok(List.of());
            return ResponseEntity.ok(appointmentService.getAppointmentsForDoctor(doctor.getId()));
        }

        // Nurse
        else if (principal.hasRole("NURSE")) {
            var nurse = nurseRepository.findByUsername(principal.getUsername()).orElse(null);
            if (nurse == null) return ResponseEntity.ok(List.of());
            return ResponseEntity.ok(appointmentService.getAppointmentsForNurse(nurse.getId()));
        }

        // Patient
        else if (principal.hasRole("PATIENT")) {
            var patient = patientRepository.findByUser_Username(principal.getUsername()).orElse(null);
            if (patient == null) return ResponseEntity.ok(List.of());
            return ResponseEntity.ok(appointmentService.getAppointmentsForPatient(patient.getId()));
        }

        return ResponseEntity.ok(List.of());
    }
}