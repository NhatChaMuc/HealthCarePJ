// lib/manage_patients_screen.dart
import 'package:flutter/material.dart';
import './api_service.dart';
import './patient.dart';

class ManagePatientsScreen extends StatefulWidget {
  final String token;
  const ManagePatientsScreen({super.key, required this.token});

  @override
  State<ManagePatientsScreen> createState() => _ManagePatientsScreenState();
}

class _ManagePatientsScreenState extends State<ManagePatientsScreen> {
  late ApiService _api;
  late Future<List<Patient>> _future;

  @override
  void initState() {
    super.initState();
    _api = ApiService(token: widget.token);
    _future = _api.getPatients();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _api.getPatients();
    });
  }

  void _deletePatient(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Ngài có chắc muốn xoá bệnh nhân này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _api.deletePatient(id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 🎨 Toàn màn hình trắng
      appBar: AppBar(
        title: const Text('Quản lý bệnh nhân'),
        backgroundColor: Colors.white, // Nền AppBar trắng
        foregroundColor: Colors.black, // Chữ đen
        elevation: 0.5, // viền mảnh tinh tế
      ),
      body: FutureBuilder<List<Patient>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                '❌ Lỗi: ${snap.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final patients = snap.data ?? [];
          if (patients.isEmpty) {
            return const Center(
              child: Text(
                'Không có bệnh nhân nào.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.blue,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: patients.length,
              itemBuilder: (context, i) {
                final p = patients[i];
                return Card(
                  color: Colors.white, // Thẻ cũng nền trắng
                  elevation: 1.5,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      p.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${p.phone} • ${p.email}\n${p.address}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePatient(p.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
