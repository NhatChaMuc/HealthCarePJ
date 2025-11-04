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
// ❗ Không đặt @RequestMapping ở class-level để có thể khai báo tuyệt đối từng endpoint
public class AppointmentController {

    private final AppointmentService appointmentService;
    private final DoctorRepository doctorRepository;
    private final NurseRepository nurseRepository;
    private final PatientRepository patientRepository;

    /**
     * 📅 Đặt lịch tự động
     * Hỗ trợ cả:
     *   - POST /api/appointments/auto-schedule   (chuẩn REST)
     *   - POST /ai/auto-schedule                 (legacy từ FE hiện tại)
     */
    @PostMapping({"/api/appointments/auto-schedule", "/ai/auto-schedule"})
    public ResponseEntity<Appointment> autoSchedule(@RequestBody Map<String, Object> body) {
        if (body == null) return ResponseEntity.badRequest().build();

        Map patientMap = (Map) body.get("patient");
        String fullName = patientMap != null && patientMap.containsKey("fullName") ? patientMap.get("fullName").toString() : null;
        String email = patientMap != null && patientMap.containsKey("email") ? patientMap.get("email").toString() : null;
        String phone = patientMap != null && patientMap.containsKey("phone") ? patientMap.get("phone").toString() : null;
        String gender = patientMap != null && patientMap.containsKey("gender") ? patientMap.get("gender").toString() : null;

        String symptom = body.containsKey("symptom") ? (String) body.get("symptom") : null;
        LocalDate preferredDate = body.containsKey("preferredDate")
                ? LocalDate.parse(body.get("preferredDate").toString().substring(0, 10))
                : null;
        String preferredWindow = body.containsKey("preferredWindow") ? (String) body.get("preferredWindow") : null;

        if (fullName == null || symptom == null || preferredDate == null || preferredWindow == null)
            return ResponseEntity.badRequest().build();

        Appointment appointment = appointmentService.autoBook(
                fullName, email, phone, gender, symptom, preferredDate, preferredWindow
        );
        return ResponseEntity.ok(appointment);
    }

    /**
     * 👤 Lịch hẹn của tôi
     * Hỗ trợ cả:
     *   - GET /api/appointments/me   (chuẩn REST)
     *   - GET /appointments/me       (legacy từ FE hiện tại)
     */
    @GetMapping({"/api/appointments/me", "/appointments/me"})
    public ResponseEntity<List<Appointment>> myAppointments(Authentication authentication) {
        UserDetailsImpl principal = (UserDetailsImpl) authentication.getPrincipal();

        if (principal.hasAuthority("ROLE_DOCTOR")) {
            var doctor = doctorRepository.findByUsername(principal.getUsername()).orElse(null);
            if (doctor == null) return ResponseEntity.ok(List.of());
            return ResponseEntity.ok(appointmentService.getAppointmentsForDoctor(doctor.getId()));
        } else if (principal.hasAuthority("ROLE_NURSE")) {
            var nurse = nurseRepository.findByUsername(principal.getUsername()).orElse(null);
            if (nurse == null) return ResponseEntity.ok(List.of());
            return ResponseEntity.ok(appointmentService.getAppointmentsForNurse(nurse.getId()));
        } else if (principal.hasAuthority("ROLE_PATIENT")) {
            var patient = patientRepository.findByUser_Username(principal.getUsername()).orElse(null);
            if (patient == null) return ResponseEntity.ok(List.of());
            return ResponseEntity.ok(appointmentService.getAppointmentsForPatient(patient.getId()));
        } else if (principal.hasAuthority("ROLE_ADMIN")) {
            return ResponseEntity.ok(appointmentService.getAllAppointments());
        }

        return ResponseEntity.ok(List.of());
    }
}
