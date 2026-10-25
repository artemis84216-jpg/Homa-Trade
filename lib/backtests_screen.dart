import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';

class BacktestsScreen extends StatefulWidget {
  const BacktestsScreen({super.key});

  @override
  State<BacktestsScreen> createState() => _BacktestsScreenState();
}

class _BacktestsScreenState extends State<BacktestsScreen> {
  List<Map<String, dynamic>> _backtests = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadBacktests();
  }

  Future<void> _loadBacktests() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllBacktests();
    setState(() {
      _backtests = data;
      _filtered = data;
      _isLoading = false;
    });
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _backtests;
      } else {
        _filtered = _backtests.where((b) =>
          (b['strategy_name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
          (b['symbol'] ?? '').toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _showBacktestDialog({Map<String, dynamic>? bt}) async {
    final isEdit = bt != null;
    final strategyController = TextEditingController(text: bt?['strategy_name']?.toString() ?? '');
    final symbolController = TextEditingController(text: bt?['symbol']?.toString() ?? '');
    final timeframeController = TextEditingController(text: bt?['timeframe']?.toString() ?? '');
    final startDateController = TextEditingController(text: bt?['start_date']?.toString() ?? getCurrentJalaliDateTime());
    final endDateController = TextEditingController(text: bt?['end_date']?.toString() ?? getCurrentJalaliDateTime());
    final rrController = TextEditingController(text: (bt?['risk_reward'] ?? 0.0).toString());
    final emotionController = TextEditingController(text: bt?['emotion']?.toString() ?? '');
    final notesController = TextEditingController(text: bt?['notes']?.toString() ?? '');
    String result = bt?['result']?.toString() ?? 'Win';
    String? imagePath = bt?['image_path'];

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش بک‌تست' : 'ثبت بک‌تست جدید', style: const TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: strategyController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام استراتژی', prefixIcon: Icon(Icons.auto_graph, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: symbolController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'جفت‌ارز/نماد', prefixIcon: Icon(Icons.currency_exchange, color: AppTheme.gold)))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: timeframeController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تایم‌فریم', prefixIcon: Icon(Icons.schedule, color: AppTheme.gold)))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: startDateController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تاریخ شروع', prefixIcon: Icon(Icons.login, color: AppTheme.green)))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: endDateController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تاریخ پایان', prefixIcon: Icon(Icons.logout, color: AppTheme.red)))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: result,
                        dropdownColor: AppTheme.cardBlack,
                        decoration: const InputDecoration(labelText: 'نتیجه', prefixIcon: Icon(Icons.emoji_events, color: AppTheme.gold)),
                        items: const [
                          DropdownMenuItem(value: 'Win', child: Text('Win (سود)', style: TextStyle(color: AppTheme.green))),
                          DropdownMenuItem(value: 'Loss', child: Text('Loss (ضرر)', style: TextStyle(color: AppTheme.red))),
                          DropdownMenuItem(value: 'BE', child: Text('BE (سر به سر)', style: TextStyle(color: AppTheme.textGrey))),
                        ],
                        onChanged: (v) => setStateDialog(() => result = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: rrController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'R:R', prefixIcon: Icon(Icons.balance, color: AppTheme.gold)))),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: emotionController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'احساسات حین ترید (مثال: مضطرب، مطمئن)', prefixIcon: Icon(Icons.psychology, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: notesController, maxLines: 3, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'یادداشت‌ها', prefixIcon: Icon(Icons.notes, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) setStateDialog(() => imagePath = image.path);
                    },
                    icon: const Icon(Icons.image, color: AppTheme.gold),
                    label: Text(imagePath != null ? 'تغییر عکس چارت' : 'انتخاب عکس چارت', style: const TextStyle(color: AppTheme.textWhite)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBlack, side: const BorderSide(color: AppTheme.gold)),
                  ),
                  if (imagePath != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(imagePath!), height: 100, width: double.infinity, fit: BoxFit.cover)),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                onPressed: () async {
                  final btData = {
                    'strategy_name': strategyController.text.trim(),
                    'symbol': symbolController.text.trim(),
                    'timeframe': timeframeController.text.trim(),
                    'start_date': startDateController.text.trim(),
                    'end_date': endDateController.text.trim(),
                    'result': result,
                    'risk_reward': double.tryParse(rrController.text) ?? 0.0,
                    'emotion': emotionController.text.trim(),
                    'notes': notesController.text.trim(),
                    'image_path': imagePath,
                    'created_at': getCurrentJalaliDateTime(),
                  };
                  if (isEdit) {
                    await DatabaseHelper.instance.updateBacktest(bt!['id'], btData);
                  } else {
                    await DatabaseHelper.instance.insertBacktest(btData);
                  }
                  Navigator.pop(ctx);
                  _loadBacktests();
                },
                child: Text(isEdit ? 'ذخیره' : 'ثبت', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBacktest(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)),
          content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteBacktest(id);
      _loadBacktests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('بک‌تست‌ها'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadBacktests)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'جستجو در استراتژی یا نماد...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filter(''); }) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filter,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _filtered.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history_edu, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('بک‌تستی ثبت نشده', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final b = _filtered[index];
                          final isWin = b['result'] == 'Win';
                          final isLoss = b['result'] == 'Loss';
                          final resColor = isWin ? AppTheme.green : (isLoss ? AppTheme.red : AppTheme.textGrey);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(backgroundColor: resColor.withOpacity(0.2), child: Icon(isWin ? Icons.trending_up : (isLoss ? Icons.trending_down : Icons.remove), color: resColor)),
                              title: Text('${b['symbol']} | ${b['timeframe']}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: Text(b['strategy_name'] ?? '', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [Expanded(child: _infoRow('شروع', b['start_date'])), Expanded(child: _infoRow('پایان', b['end_date']))]),
                                      const SizedBox(height: 8),
                                      Row(children: [Expanded(child: _infoRow('نتیجه', b['result'], color: resColor)), Expanded(child: _infoRow('R:R', b['risk_reward'].toString()))]),
                                      const SizedBox(height: 8),
                                      if ((b['emotion'] ?? '').isNotEmpty) _infoRow('احساسات', b['emotion']),
                                      if ((b['notes'] ?? '').isNotEmpty) _infoRow('یادداشت', b['notes']),
                                      if (b['image_path'] != null) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(b['image_path']!), width: double.infinity, fit: BoxFit.cover)),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showBacktestDialog(bt: b)),
                                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteBacktest(b['id'])),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBacktestDialog(),
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('ثبت بک‌تست'),
      ),
    );
  }

  Widget _infoRow(String label, String? value, {Color color = AppTheme.textWhite}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value ?? '-', style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}