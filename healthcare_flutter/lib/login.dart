import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ignore: constant_identifier_names
const String FDA_API_KEY = '8RklgUnCR0052L39gRUe6Oo8X0c5Xb6DjyPgSnWZ';
// ignore: constant_identifier_names
const String GEMINI_API_KEY = 'AIzaSyALt1XKo1q0fyxPPiLFSQvqPqCeFd8ARAQ';

/// A Flutter screen that fetches drug information from the openFDA API and
/// summarizes it in Vietnamese using Gemini.  Summaries are color coded to
/// highlight key sections such as "Công dụng chính" (dark green), "Liều dùng"
/// (dark orange), "Cảnh báo" / "Chống chỉ định" (dark red), "Tác dụng phụ"
/// (dark purple), "Phụ nữ mang thai / cho con bú" (dark pink) and
/// "Lưu ý" / "Quan trọng" (dark blue).  For example:
///
/// | Mục                              | Màu hiển thị |
/// | -------------------------------- | ------------ |
/// | 🟢 Công dụng chính               | Xanh lá đậm  |
/// | 🟠 Liều dùng                     | Cam đậm      |
/// | 🔴 Cảnh báo / Chống chỉ định     | Đỏ đậm       |
/// | 🟣 Tác dụng phụ phổ biến         | Tím đậm      |
/// | 🌸 Phụ nữ mang thai / cho con bú | Hồng đậm     |
/// | 🔵 Lưu ý / Quan trọng            | Xanh biển    |
///
/// The categories and corresponding colors are applied when
/// displaying the summarized text.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Controller for the drug name input.  Users can type a brand name or
  /// active ingredient here.  The text field is empty by default; pressing
  /// return or a button triggers a search.
  final TextEditingController _drugCtrl = TextEditingController();

  /// Indicates whether data is currently being fetched.
  bool _loading = false;

  /// Holds any error message to display to the user.
  String? _error;

  /// A list of maps representing rows of information to display.  Each map
  /// corresponds to a single drug entry returned by the API.  Keys in the
  /// map determine the label shown on screen, and values are the
  /// corresponding text.
  List<Map<String, dynamic>> _items = [];

  // ---------------------------------------------------------------------------
  // Data fetching and summarization
  // ---------------------------------------------------------------------------

  /// Uses the Gemini API to summarize an English description of a drug into
  /// Vietnamese.  The summary includes key sections requested in the prompt.
  ///
  /// If the English text is empty, returns a placeholder.  This method
  /// communicates with the generative language service and may take up to
  /// 25 seconds before timing out.
  Future<String> _summarizeWithGemini(String englishText) async {
    if (englishText.trim().isEmpty) return '(Khong co noi dung)';

    const endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

    final prompt = '''
Ban la bac si tro ly trong he thong y te.
Hay tom tat ngan gon va de hieu bang tieng Viet cho benh nhan dua tren noi dung sau.
Trinh bay ro rang cac muc sau (chi dien nhung gi co trong du lieu):
- Cong dung chinh
- Lieu dung (neu co trong du lieu)
- Canh bao va chong chi dinh
- Tac dung phu pho bien
- Luu y cho phu nu mang thai hoac cho con bu (neu co)

Du lieu tieng Anh:
$englishText
''';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    };

    try {
      final resp = await http
          .post(
            Uri.parse('$endpoint?key=$GEMINI_API_KEY'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 25));

      if (resp.statusCode != 200) {
        return '(Loi Gemini HTTP ${resp.statusCode})';
      }

      final data = jsonDecode(resp.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      return text?.trim() ?? '(Khong the tom tat)';
    } catch (e) {
      return '(Loi khi goi Gemini: $e)';
    }
  }

  /// Fetches drug data from the openFDA API.  Depending on the endpoint,
  /// this method retrieves general label information (label.json), side
  /// effects (event.json) or NDC codes (ndc.json).  After fetching
  /// results, it calls [_summarizeWithGemini] to translate and summarize
  /// relevant text into Vietnamese.
  Future<void> _fetchDrug(String endpoint, String query) async {
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
    });

    if (query.isEmpty) {
      setState(() {
        _error = '⚠️ Vui lòng nhập tên thuốc.';
        _loading = false;
      });
      return;
    }

    try {
      final uri = Uri.https(
        'api.fda.gov',
        '/drug/$endpoint',
        {'search': query, 'limit': '3', 'api_key': FDA_API_KEY},
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        setState(() => _error = 'Lỗi HTTP ${resp.statusCode}');
        return;
      }

      final jsonData = json.decode(resp.body);
      final results = jsonData['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        setState(() => _error = 'Không tìm thấy dữ liệu cho thuốc này.');
        return;
      }

      List<Map<String, dynamic>> temp = [];

      if (endpoint == 'label.json') {
        // Fetch drug label information
        for (var r in results) {
          final fda = r['openfda'] ?? {};
          final englishName = (fda['brand_name'] != null)
              ? (fda['brand_name'] as List).join(', ')
              : 'Unknown';

          final englishText = '''
Ten thuoc: $englishName
Cong dung: ${(r['indications_and_usage'] != null) ? (r['indications_and_usage'] as List).join(' ') : 'Khong co'}
Canh bao: ${(r['warnings_and_cautions'] != null) ? (r['warnings_and_cautions'] as List).join(' ') : 'Khong co'}
Tac dung phu: ${(r['adverse_reactions'] != null) ? (r['adverse_reactions'] as List).join(' ') : 'Khong co'}
Phu nu mang thai: ${(r['pregnancy'] != null) ? (r['pregnancy'] as List).join(' ') : 'Khong co'}
''';

          final vietnameseSummary = await _summarizeWithGemini(englishText);

          temp.add({
            'Ten thuoc': englishName,
            'Hang san xuat': (fda['manufacturer_name'] != null)
                ? (fda['manufacturer_name'] as List).join(', ')
                : 'Khong ro',
            'Tom tat bac si': vietnameseSummary,
          });
        }
      } else if (endpoint == 'event.json') {
        // Fetch side effect information
        for (var r in results) {
          final patient = r['patient'] ?? {};
          final reactions = (patient['reaction'] as List?)
              ?.map((e) => e['reactionmeddrapt'])
              .whereType<String>()
              .toList();

          final englishSide =
              reactions != null ? reactions.take(6).join(', ') : 'No data';
          final vietnameseSide = await _summarizeWithGemini(
              'Cac tac dung phu duoc bao cao: $englishSide');

          temp.add({
            'Tac dung phu pho bien (dich)': vietnameseSide,
            'Quoc gia bao cao':
                patient['reportercountry']?.toString() ?? 'Khong ro',
          });
        }
      } else if (endpoint == 'ndc.json') {
        // Fetch NDC information
        for (var r in results) {
          final englishName = r['brand_name']?.toString() ?? 'Unknown';
          final summary = await _summarizeWithGemini(
              'Ten thuoc: $englishName\nMa NDC: ${r['product_ndc']}');

          temp.add({
            'Ten thuoc': englishName,
            'Ma NDC': r['product_ndc']?.toString() ?? 'Khong ro',
            'Hang san xuat': r['labeler_name']?.toString() ?? 'Khong ro',
            'Tom tat': summary,
          });
        }
      }

      setState(() => _items = temp);
    } on TimeoutException {
      setState(() => _error = '⏱ Quá thời gian chờ (15s)');
    } on SocketException {
      setState(() => _error = '🚫 Lỗi mạng hoặc không có Internet');
    } catch (e) {
      setState(() => _error = 'Lỗi không xác định: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UI Rendering
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra cứu thuốc (openFDA + Gemini)'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _drugCtrl,
              decoration: InputDecoration(
                labelText: 'Nhập tên thuốc (vd: ibuprofen, tylenol...)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _fetchDrug(
                'label.json',
                'openfda.brand_name:${_drugCtrl.text.trim()}',
              ),
            ),
            const SizedBox(height: 10),
            // Buttons for different types of information
            Wrap(
              spacing: 8,
              children: [
                _buildButton(
                    Icons.info,
                    'Thông tin thuốc',
                    Colors.blue,
                    () => _fetchDrug('label.json',
                        'openfda.brand_name:${_drugCtrl.text.trim()}')),
                _buildButton(
                    Icons.qr_code,
                    'Mã thuốc (NDC)',
                    Colors.deepPurple,
                    () => _fetchDrug(
                        'ndc.json', 'brand_name:${_drugCtrl.text.trim()}')),
                _buildButton(
                    Icons.warning_amber_rounded,
                    'Tác dụng phụ',
                    Colors.redAccent,
                    () => _fetchDrug('event.json',
                        'patient.drug.medicinalproduct:${_drugCtrl.text.trim()}')),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
            // Display results
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text(
                        'Nhập tên thuốc và chọn loại thông tin cần tra.',
                        style: TextStyle(fontSize: 15),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, i) => _buildDrugCard(_items[i], i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a styled button used to trigger various types of searches.
  Widget _buildButton(
      IconData icon, String label, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _loading ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  /// Builds a card summarizing information for a single drug.  Each key/value
  /// pair in [item] becomes a separate section in the card.  The summary
  /// values are parsed for keywords to highlight specific sections with the
  /// color scheme defined above.
  Widget _buildDrugCard(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: item.entries.map((e) {
            final key = e.key;
            final rawValue = e.value.toString();

            // Clean markdown markers from the text
            final cleanValue = rawValue
                .replaceAll(RegExp(r'\*\*?'), '')
                .replaceAll(RegExp(r'[_#>`]'), '')
                .replaceAll(RegExp(r'\n{2,}'), '\n')
                .trim();

            // Determine the icon and main color for the card row
            Color mainColor = Colors.teal;
            IconData rowIcon = Icons.medical_information;

            // Split the clean summary into lines and assign colors based on
            // keywords that indicate specific sections.  Each line becomes
            // a TextSpan with its own color.  The mapping corresponds to
            // the legend:
            // - Cong dung chinh -> dark green
            // - Lieu dung -> dark orange
            // - Canh bao / Chong chi dinh -> dark red
            // - Tac dung phu -> dark purple
            // - Phu nu mang thai / cho con bu -> dark pink
            // - Luu y / Quan trong -> dark blue
            List<TextSpan> spans = [];
            for (var line in cleanValue.split('\n')) {
              Color lineColor = Colors.black;
              final lower = line.toLowerCase();

              if (lower.contains('công dụng')) {
                lineColor = Colors.green.shade700; // xanh lá đậm
              } else if (lower.contains('liều dùng')) {
                lineColor = Colors.orange.shade700; // cam đậm
              } else if (lower.contains('cảnh báo') ||
                  lower.contains('chống chỉ định')) {
                lineColor = Colors.red.shade700; // đỏ đậm
              } else if (lower.contains('tác dụng phụ')) {
                lineColor = Colors.purple.shade700; // tím đậm
              } else if (lower.contains('phụ nữ mang thai') ||
                  lower.contains('cho con bú')) {
                lineColor = Colors.pink.shade700; // hồng đậm
              } else if (lower.contains('lưu ý') ||
                  lower.contains('quan trọng')) {
                lineColor = Colors.blue.shade700; // xanh biển
              }

              spans.add(TextSpan(
                text: '$line\n',
                style: TextStyle(
                  color: lineColor,
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ));
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(rowIcon, color: mainColor, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: '$key:\n',
                        style: TextStyle(
                          fontSize: 15,
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                        ),
                        children: spans,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
