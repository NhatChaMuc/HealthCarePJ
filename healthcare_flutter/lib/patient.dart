// lib/patient.dart
class Patient {
  final String id;       // UUID từ BE -> String
  final String firstName;
  final String lastName;
  final String dob;
  final String phone;
  final String email;    // users.username hoặc patient.email
  final String address;

  const Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.phone,
    required this.email,
    required this.address,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    // id có thể là UUID (String) hoặc số -> ép về String
    final String id = (json['id'] ?? '').toString();

    // fullName có ở bảng users; patient có firstName/lastName
    final String fullName =
        (json['fullName'] ?? '').toString().trim();

    // Ưu tiên first/last, fallback tách từ fullName
    String first = (json['firstName'] ?? json['first_name'] ?? '').toString();
    String last  = (json['lastName']  ?? json['last_name']  ?? '').toString();

    if (first.isEmpty && last.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        first = parts.sublist(0, parts.length - 1).join(' ');
        last  = parts.last;
      } else {
        first = fullName;
      }
    }

    return Patient(
      id: id,
      firstName: first,
      lastName: last,
      dob: (json['dob'] ?? json['dateOfBirth'] ?? '').toString(),
      phone: (json['phone'] ?? json['mobile'] ?? '').toString(),
      // users trả username là email đăng nhập
      email: (json['email'] ?? json['username'] ?? '').toString(),
      address: (json['address'] ?? json['addr'] ?? '').toString(),
    );
  }

  String get fullName {
    final fn = firstName.trim();
    final ln = lastName.trim();
    final s = ('$fn $ln').trim();
    return s.isEmpty ? email : s;
  }
}
