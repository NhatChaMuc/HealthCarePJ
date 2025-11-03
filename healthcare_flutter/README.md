# Healthcare Flutter (Frontend)

Frontend Flutter cho hệ thống quản lý y tế (bệnh nhân, bác sĩ, lịch hẹn).

## Chạy nhanh
```bash
flutter pub get
flutter run
```
> Nếu chạy web: `flutter run -d chrome`

## Thư mục chính
- `lib/models`: Patient, Doctor, Appointment
- `lib/repositories`: AppRepository (đọc dữ liệu mock, có thể thay bằng REST)
- `lib/providers`: AppState (Provider)
- `lib/screens`: Login, Dashboard, Patients, Doctors, Appointments
- `assets/mock_data.json`: dữ liệu mẫu

## Đổi sang backend REST
- Thay thế `services/api_client.dart` để gọi HTTP tới API thật (Spring Boot, FastAPI...)
- Ví dụ:
```dart
// final res = await http.get(Uri.parse('https://api.example.com/patients'));
```
