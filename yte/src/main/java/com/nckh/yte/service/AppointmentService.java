package com.nckh.yte.service;

import com.nckh.yte.entity.*;
import com.nckh.yte.repository.*;
import com.nckh.yte.security.UserDetailsImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class AppointmentService {

    private final AppointmentRepository appointmentRepository;
    private final PatientRepository patientRepository;
    private final DoctorRepository doctorRepository;
    private final NurseRepository nurseRepository;
    private final UserRepository userRepository;
    private final GeminiService geminiService;

    // === CÁC HÀM GET ===
    public List<Appointment> getAppointmentsForDoctor(UUID doctorId) {
        return appointmentRepository.findByDoctorId(doctorId);
    }

    public List<Appointment> getAppointmentsForNurse(UUID nurseId) {
        return appointmentRepository.findByNurseId(nurseId);
    }

    public List<Appointment> getAppointmentsForPatient(UUID patientId) {
        return appointmentRepository.findByPatientId(patientId);
    }

    public Appointment create(Appointment appointment) {
        return appointmentRepository.save(appointment);
    }

    public List<Appointment> getAllAppointments() {
        return appointmentRepository.findAll();
    }


    // === HÀM AUTOBOOK (FIX LOGIC) ===
    @Transactional
    public Appointment autoBook(String patientName, String email, String phone, String gender,
                                String symptom, LocalDate preferredDate, String preferredWindow) {

        Patient patient = null;
        User user = null;

        // ✅ BƯỚC 1: SỬ DỤNG GEMINI ĐỂ XÁC ĐỊNH CHUYÊN KHOA
        String requiredSpecialty = null;
        try {
            requiredSpecialty = geminiService.determineSpecialtyFromSymptom(symptom);
        } catch (Exception e) {
            System.err.println("Lỗi nghiêm trọng khi gọi GeminiService, chuyển sang logic cũ. Lỗi: " + e.getMessage());
        }

        if (requiredSpecialty == null || requiredSpecialty.trim().isEmpty()) {
            System.out.println("GEMINI FAILED hoặc trả về rỗng. Đang dùng logic dự phòng (legacy).");
            requiredSpecialty = determineSpecialtyLegacy(symptom); 
        } else {
            System.out.println("GEMINI SUCCESS: Chuyên khoa được xác định: " + requiredSpecialty);
        }

        // ✅ BƯỚC 2: Tìm User hiện tại
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof UserDetailsImpl principal) {
            if (principal.hasRole("PATIENT")) {
                user = userRepository.findByUsername(principal.getUsername()).orElse(null);
                if (user != null) {
                    patient = patientRepository.findByUser(user).orElse(null);
                }
            }
        }

        // ✅ BƯỚC 3: Logic tạo Patient Profile (Nếu User đã tồn tại nhưng Profile Patient chưa có)
        if (patient == null && user != null) {
            // User đã tồn tại (đã đăng nhập) nhưng chưa có hồ sơ Patient
            String fn, ln;
            String fullName = user.getFullName() != null ? user.getFullName() : patientName;

            if (fullName != null && !fullName.trim().isEmpty()) {
                String[] parts = fullName.trim().split("\\s+", 2);
                fn = parts.length > 0 ? parts[0] : "";
                ln = parts.length > 1 ? parts[1] : "";
            } else {
                fn = "";
                ln = "";
            }

            patient = patientRepository.save(
                    Patient.builder()
                            .firstName(fn)
                            .lastName(ln)
                            .user(user) // Gán User đã tồn tại
                            .department(requiredSpecialty)
                            .email(email)
                            .phone(phone)
                            .gender(gender)
                            .build()
            );
        } else if (patient == null && user == null) {
             // ⚠️ TRƯỜNG HỢP NÀY KHÔNG NÊN XẢY RA: User chưa đăng nhập.
             // Nếu xảy ra, cần logic tạo User MỚI (và Role PATIENT) trước khi tạo Patient.
             // Vì ta đang giả định User đã đăng nhập, ta sẽ báo lỗi nếu không tìm thấy User.
             throw new RuntimeException("Lỗi logic: User không xác định.");
        }

        // ✅ BƯỚC 4: CHỌN BÁC SĨ (Logic giữ nguyên)
        List<Doctor> specialists = doctorRepository.findBySpecialtyIgnoreCase(requiredSpecialty);
        Doctor doctor;
        
        if (!specialists.isEmpty()) {
            doctor = specialists.get(new Random().nextInt(specialists.size()));
        } else {
            List<Doctor> generalists = doctorRepository.findBySpecialtyIgnoreCase("Đa khoa");
            if (!generalists.isEmpty()) {
                System.out.println("Không tìm thấy BS chuyên khoa: " + requiredSpecialty + ". Chuyển về Đa khoa.");
                doctor = generalists.get(new Random().nextInt(generalists.size()));
            } else {
                List<Doctor> allDoctors = doctorRepository.findAll();
                doctor = allDoctors.isEmpty() ? null : allDoctors.get(new Random().nextInt(allDoctors.size()));
            }
        }

        // ✅ BƯỚC 5: Tạo Appointment (Logic giữ nguyên)
        LocalDateTime startTime;
        try {
            String startTimeStr = preferredWindow.split("\\s*-\\s*")[0]; 
            LocalTime time = LocalTime.parse(startTimeStr); 
            startTime = preferredDate.atTime(time); 
        } catch (Exception e) {
            startTime = preferredDate.atTime(8, 0); 
        }
        LocalDateTime endTime = startTime.plusMinutes(30);

        Appointment appointment = Appointment.builder()
                .patient(patient)
                .doctor(doctor)
                .startTime(startTime)
                .endTime(endTime)
                .symptom(symptom)
                .status(AppointmentStatus.PENDING)
                .preferredDate(preferredDate)
                .preferredWindow(preferredWindow)
                .build();

        return appointmentRepository.save(appointment);
    }

    private String determineSpecialtyLegacy(String reason) {
        if (reason == null || reason.trim().isEmpty()) return "Đa khoa";
        String r = reason.toLowerCase();
        if (r.contains("tim") || r.contains("huyết áp")) return "Tim mạch";
        if (r.contains("xương") || r.contains("khớp") || r.contains("đau lưng")) return "Cơ xương khớp";
        if (r.contains("tai") || r.contains("mũi") || r.contains("họng")) return "Tai mũi họng";
        if (r.contains("da") || r.contains("ngứa")) return "Da liễu";
        if (r.contains("răng") || r.contains("nướu")) return "Răng hàm mặt";
        return "Đa khoa";
    }
}