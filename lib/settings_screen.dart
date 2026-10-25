import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _brokers = [];

  @override
  void initState() {
    super.initState();
    _loadBrokers();
  }

  Future<void> _loadBrokers() async {
    final data = await DatabaseHelper.instance.getAllBrokerAccounts();
    setState(() => _brokers = data);
  }

  Future<void> _changePassword() async {
    if (_currentPassController.text.isEmpty || _newPassController.text.isEmpty || _confirmPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفاً تمام فیلدها را پر کنید'), backgroundColor: Colors.red));
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز جدید و تکرار آن مطابقت ندارند'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('trade_password') ?? '1234';
      
      if (_currentPassController.text != savedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رمز فعلی اشتباه است'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
        return;
      }

      await prefs.setString('trade_password', _newPassController.text);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ رمز عبور با موفقیت تغییر کرد'), backgroundColor: Colors.green));
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _backupDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final sourcePath = '$dbPath/homa_trade.db';
      final tempDir = await getTemporaryDirectory();
      final backupPath = '${tempDir.path}/homa_trade_backup_${DateTime.now().millisecondsSinceEpoch}.db';
      
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فایل دیتابیس یافت نشد'), backgroundColor: Colors.red));
        return;
      }
      
      await sourceFile.copy(backupPath);
      await Share.shareXFiles([XFile(backupPath)], text: 'پشتیبان Homa_Trade - ${getCurrentJalaliDateTime()}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ فایل پشتیبان آماده اشتراک‌گذاری شد'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در پشتیبان‌گیری: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _resetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('⚠️ هشدار جدی', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: const Text('این عمل تمام اطلاعات را برای همیشه پاک می‌کند. آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بله، پاک کن', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
    if (confirm == true) {
     