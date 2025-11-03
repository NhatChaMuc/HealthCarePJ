import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Các màn hình con
import 'create_doctor_screen.dart';
import 'create_nurse_screen.dart';
import 'chat_widget.dart';
import 'manage_accounts_screen.dart';
import 'manage_patients_screen.dart';
import 'manage_appointments_screen.dart';
import 'book_appointment_auto_screen.dart';
import 'lookup_medicine_screen.dart'; // ✅ Thêm màn hình tra cứu thuốc

/// ===============================
/// ROLES - Chống sai chính tả
/// ===============================
class Roles {
  static const admin = 'ADMIN';
  static const doctor = 'DOCTOR';
  static const nurse = 'NURSE';
  static const patient = 'PATIENT';

  static String norm(String s) => s.trim().toUpperCase();
}

/// ===============================
/// DASHBOARD SCREEN
/// ===============================
class DashboardScreen extends StatefulWidget {
  final String fullName;
  final String role;
  final String token;

  const DashboardScreen({
    super.key,
    required this.fullName,
    required this.role,
    required this.token,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late List<_MenuItem> _menuItems;
  late List<String> _pageTitles;

  @override
  void initState() {
    super.initState();
    _setupMenuByRole(widget.role);
  }

  /// ===============================
  /// MENU THEO ROLE
  /// ===============================
  void _setupMenuByRole(String role) {
    final r = Roles.norm(role);

    if (r == Roles.admin) {
      _menuItems = const [
        _MenuItem(icon: Icons.people_outline, label: 'Account'),
        _MenuItem(icon: Icons.add_circle_outline, label: 'Create Doctor'),
        _MenuItem(icon: Icons.person_add_alt_1_outlined, label: 'Create Nurse'),
        _MenuItem(icon: Icons.bar_chart_outlined, label: 'Reports'),
        _MenuItem(icon: Icons.settings_outlined, label: 'Settings'),
      ];

      _pageTitles = [
        "Manage Account",
        "Create Doctor Account",
        "Create Nurse Account",
        "Reports",
        "Settings",
      ];
    } 
    else if (r == Roles.doctor || r == Roles.nurse) {
      _menuItems = const [
        _MenuItem(icon: Icons.people, label: 'Patients'),
        _MenuItem(icon: Icons.event_note, label: 'Appointments'),
        _MenuItem(icon: Icons.medication_outlined, label: 'Medicine Lookup'), // ✅ thêm tab tra cứu thuốc
        _MenuItem(icon: Icons.settings_outlined, label: 'Settings'),
      ];

      _pageTitles = [
        "Manage Patients",
        "Appointments",
        "Medicine Lookup", // ✅ khớp case hiển thị
        "Settings",
      ];
    } 
    else if (r == Roles.patient) {
      _menuItems = const [
        _MenuItem(icon: Icons.add_alarm_outlined, label: 'Book Appointment'),
        _MenuItem(icon: Icons.event_note, label: 'My Appointments'),
        _MenuItem(icon: Icons.settings_outlined, label: 'Settings'),
      ];

      _pageTitles = [
        "Book Appointment",
        "My Appointments",
        "Settings",
      ];
    }

    if (_selectedIndex >= _menuItems.length) _selectedIndex = 0;
  }

  /// ===============================
  /// LOGOUT
  /// ===============================
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// MAIN UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) =>
                    setState(() => _selectedIndex = index),
                role: widget.role,
                fullName: widget.fullName,
                menuItems: _menuItems,
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pageTitles[_selectedIndex],
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(child: _buildContent(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Chat nổi bên phải (cho bệnh nhân)
          if (Roles.norm(widget.role) == Roles.patient)
            ChatWidget(
              userId: widget.fullName,
              token: widget.token,
              role: widget.role,
            ),
        ],
      ),
    );
  }

  /// ===============================
  /// NỘI DUNG MỖI TAB
  /// ===============================
  Widget _buildContent(BuildContext context) {
    switch (_pageTitles[_selectedIndex]) {
      // ADMIN
      case "Manage Account":
        return ManageAccountsScreen(adminToken: widget.token);

      case "Create Doctor Account":
        return CreateDoctorScreen(adminToken: widget.token);

      case "Create Nurse Account":
        return CreateNurseScreen(adminToken: widget.token);

      case "Reports":
        return _msg("📊 Reports & System Statistics");

      // DOCTOR & NURSE
      case "Manage Patients":
        return ManagePatientsScreen(token: widget.token);

      case "Appointments":
        return ManageAppointmentsScreen(
          token: widget.token,
          role: widget.role,
        );

      case "Medicine Lookup": // ✅ tab mới
        return LookupMedicineScreen(token: widget.token);

      // PATIENT
      case "Book Appointment":
        return BookAppointmentAutoScreen(token: widget.token);

      case "My Appointments":
        return ManageAppointmentsScreen(
          token: widget.token,
          role: widget.role,
        );

      // SETTINGS
      case "Settings":
        return Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () => _handleLogout(context),
            label: const Text("Logout", style: TextStyle(fontSize: 16)),
          ),
        );

      default:
        return _msg("❓ Unknown Tab");
    }
  }

  /// ===============================
  /// TIỆN ÍCH: THÔNG BÁO ĐƠN GIẢN
  /// ===============================
  Widget _msg(String text) => Center(
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 18, color: Colors.black87),
          textAlign: TextAlign.center,
        ),
      );
}

/// ===============================
/// SIDEBAR MENU
/// ===============================
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final String role;
  final String fullName;
  final List<_MenuItem> menuItems;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.role,
    required this.fullName,
    required this.menuItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFFE7F2F9),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header user info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis),
                      Text(role,
                          style: GoogleFonts.inter(
                              color: Colors.blueGrey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Brand
          Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.local_hospital,
                  color: Colors.blueAccent, size: 28),
              const SizedBox(width: 8),
              Text('Health Life',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 25),

          // Menu items
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final active = index == selectedIndex;
                return InkWell(
                  onTap: () => onItemSelected(index),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: ListTile(
                      leading: Icon(item.icon,
                          color: active ? Colors.blueAccent : Colors.black54),
                      title: Text(item.label,
                          style: TextStyle(
                            color: active ? Colors.blueAccent : Colors.black87,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
/// ===============================
/// MENU ITEM CLASS
/// ===============================
class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}
