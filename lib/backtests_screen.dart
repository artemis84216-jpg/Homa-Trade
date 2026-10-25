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
  void initState() { super.initState(); _loadBacktests(); }

  Future<void> _loadBacktests() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllBacktests();
    setState(() { _backtests = data; _filtered = data; _isLoading = false; });
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) { _filtered = _backtests; } 
      else {
        _filtered = _backtests.where((b) => (b['strategy_name'] ?? '').toLowerCase().contains(query.toLowerCase()) || (b['symbol'] ?? '').toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            panEnabled: true, boundaryMargin: const EdgeInsets.all(20), minScale: 0.5, maxScale: 4.0,
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                  Expanded(child: TextField(controller: endDateController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تاریخ پایان', prefixIcon: Icon(Icons.logout, color: Colors.red)))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(value: result, dropdownColor: AppTheme.cardBlack, decoration: const InputDecoration(labelText: 'نتیجه', prefixIcon: Icon(Icons.emoji_events, color: AppTheme.gold)), items: const [DropdownMenuItem(value: 'Win', child: Text('Win (سود)', style: TextStyle(color: AppTheme.green))), DropdownMenuItem(value: 'Loss', child: Text('Loss (ضرر)', style: TextStyle(color: AppTheme.red))), DropdownMenuItem(value: 'BE', child: Text('BE (سر به سر)', style: TextStyle(color: AppTheme.textGrey)))], onChanged: (v) => setStateDialog(() => result = v!))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: rrController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'R:R', prefixIcon: Icon(Icons.balance, color: AppTheme.gold)))),
                ]),
                const SizedBox(height: 12),
                TextField(controller: emotionController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'احساسات حین ترید', prefixIcon: Icon(Icons.psychology, color: AppTheme.gold))),
                const SizedBox(height: 12),
                TextField(controller: notesController, maxLines: 3