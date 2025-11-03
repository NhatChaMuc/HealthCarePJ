// lib/manage_appointments_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './app_config.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  final String token;
  final String role; // DOCTOR | NURSE | PATIENT

  const ManageAppointmentsScreen({
    super.key,
    required this.token,
    required this.role,
  });

  @override
  State<ManageAppointmentsScreen> createState() =>
      _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchAppointmentsMe();
  }

  Future<List<Map<String, dynamic>>> _fetchAppointmentsMe() async {
    final url = Uri.parse('${AppConfig.baseUrl}/appointments/me');

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    print('📡 GET $url -> ${res.statusCode}');
    print('📥 ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Lỗi tải lịch hẹn: HTTP ${res.statusCode} - ${res.body}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    List<dynamic> raw;
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map<String, dynamic>) {
      raw = (decoded['data'] ??
              decoded['content'] ??
              decoded['items'] ??
              decoded['result'] ??
              decoded['appointments'] ??
              []) as List<dynamic>;
    } else {
      raw = const [];
    }

    final normalized = raw.map<Map<String, dynamic>>((e) {
      final m = Map<String, dynamic>.from(e as Map);

      final id = m['id'] ?? m['appointmentId'] ?? m['appointment_id'];
      final patientName = m['patientName'] ??
          m['patient_name'] ??
          m['patient']?['fullName'] ??
          m['patient']?['name'];
      final doctorName = m['doctorName'] ??
          m['doctor_name'] ??
          m['doctor']?['fullName'] ??
          m['doctor']?['name'];

      final startRaw =
          m['startTime'] ?? m['start_time'] ?? m['date'] ?? m['start'];
      final endRaw = m['endTime'] ?? m['end_time'] ?? m['end'];
      final reason = m['reason'] ?? m['note'] ?? m['symptom'] ?? '—';

      return {
        'id': id,
        'patientName': patientName,
        'doctorName': doctorName,
        'start': _normalizeDateString(startRaw),
        'end': _normalizeDateString(endRaw),
        'reason': reason,
        '_raw': m,
      };
    }).toList();

    return normalized;
  }

  String _normalizeDateString(dynamic v) {
    if (v == null) return 'Không rõ';
    final s = v.toString();
    try {
      final dt = DateTime.parse(s);
      return _fmtDateTime(dt);
    } catch (_) {
      try {
        final s2 = s.replaceAll(' ', 'T');
        final dt = DateTime.parse(s2);
        return _fmtDateTime(dt);
      } catch (_) {
        return s;
      }
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtDateTime(DateTime dt) =>
      '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';

  Future<void> _refresh() async {
    setState(() {
      _future = _fetchAppointmentsMe();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = widget.role.toUpperCase() == 'DOCTOR' ||
        widget.role.toUpperCase() == 'NURSE';
    final title = isDoctor ? '📋 Lịch hẹn của bác sĩ' : '📅 Lịch hẹn của tôi';

    return Scaffold(
      backgroundColor: Colors.white, // ✅ Nền trắng toàn màn hình
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white, // ✅ AppBar trắng
        foregroundColor: Colors.black, // ✅ Chữ đen
        elevation: 0, // ✅ Không đổ bóng
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '❌ ${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }

            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Không có cuộc hẹn nào.')),
                ],
              );
            }

            return Container(
              color: Colors.white, // ✅ Nền danh sách trắng đồng bộ
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final ap = items[i];
                  final patientName = ap['patientName'] ??
                      'Bệnh nhân #${ap['_raw']?['patientId'] ?? ap['_raw']?['patient_id'] ?? ''}';
                  final doctorName = ap['doctorName'] ??
                      'Bác sĩ #${ap['_raw']?['doctorId'] ?? ap['_raw']?['doctor_id'] ?? ''}';
                  final start = ap['start'] ?? 'Không rõ';
                  final end = ap['end'];
                  final reason = ap['reason'] ?? '—';

                  final subtitle = isDoctor
                      ? '👤 $patientName\n🕒 $start${end != null ? ' → $end' : ''}'
                      : '🩺 $doctorName\n🕒 $start${end != null ? ' → $end' : ''}';

                  return Card(
                    color: Colors.white, // ✅ Thẻ trắng đồng bộ
                    elevation: 0.8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Icon(Icons.event,
                          color: isDoctor ? Colors.green : Colors.blueAccent),
                      title: Text(reason,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                      subtitle: Text(subtitle,
                          style: const TextStyle(color: Colors.black87)),
                      isThreeLine: false,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
