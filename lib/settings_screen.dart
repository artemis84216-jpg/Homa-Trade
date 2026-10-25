import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart'; // <-- این خط اضافه شد
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
      await DatabaseHelper.instance.resetDatabase();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ دیتابیس پاک شد'), backgroundColor: Colors.green));
      _loadBrokers();
    }
  }

  Future<void> _showBrokerDialog({Map<String, dynamic>? broker}) async {
    final isEdit = broker != null;
    final nameController = TextEditingController(text: broker?['broker_name']?.toString() ?? '');
    final typeController = TextEditingController(text: broker?['account_type']?.toString() ?? '');
    final userController = TextEditingController(text: broker?['username']?.toString() ?? '');
    final passController = TextEditingController(text: broker?['password']?.toString() ?? '');
    final urlController = TextEditingController(text: broker?['login_url']?.toString() ?? '');
    final balanceController = TextEditingController(text: (broker?['balance'] ?? 0).toString());
    final notesController = TextEditingController(text: broker?['notes']?.toString() ?? '');
    bool _obscurePass = true;

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش حساب' : 'افزودن حساب جدید', style: const TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام بروکر/صرافی', prefixIcon: Icon(Icons.account_balance, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: typeController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نوع حساب (مثال: Real, Demo)', prefixIcon: Icon(Icons.category, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: userController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام کاربری / شماره حساب', prefixIcon: Icon(Icons.person, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passController,
                    obscureText: _obscurePass,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: InputDecoration(
                      labelText: 'رمز عبور',
                      prefixIcon: const Icon(Icons.lock, color: AppTheme.gold),
                      suffixIcon: IconButton(icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: AppTheme.gold), onPressed: () => setStateDialog(() => _obscurePass = !_obscurePass)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: urlController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'لینک ورود', prefixIcon: Icon(Icons.link, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: balanceController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'موجودی فعلی', prefixIcon: Icon(Icons.attach_money, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: notesController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes, color: AppTheme.gold))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                onPressed: () async {
                  final brokerData = {
                    'broker_name': nameController.text.trim(),
                    'account_type': typeController.text.trim(),
                    'username': userController.text.trim(),
                    'password': passController.text.trim(),
                    'login_url': urlController.text.trim(),
                    'balance': double.tryParse(balanceController.text) ?? 0,
                    'notes': notesController.text.trim(),
                    'created_at': getCurrentJalaliDateTime(),
                  };
                  if (isEdit) {
                    await DatabaseHelper.instance.updateBrokerAccount(broker!['id'], brokerData);
                  } else {
                    await DatabaseHelper.instance.insertBrokerAccount(brokerData);
                  }
                  Navigator.pop(ctx);
                  _loadBrokers();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBroker(int id) async {
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
      await DatabaseHelper.instance.deleteBrokerAccount(id);
      _loadBrokers();
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('خروج از برنامه', style: TextStyle(color: AppTheme.gold)),
          content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
              child: const Text('بله', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('تنظیمات'), centerTitle: true),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // تغییر رمز
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.lock, color: AppTheme.gold), SizedBox(width: 8), Text('تغییر رمز عبور', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 16),
                      TextField(controller: _currentPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز فعلی', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.gold))),
                      const SizedBox(height: 12),
                      TextField(controller: _newPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'رمز جدید', prefixIcon: Icon(Icons.key, color: AppTheme.gold))),
                      const SizedBox(height: 12),
                      TextField(controller: _confirmPassController, obscureText: true, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تکرار رمز جدید', prefixIcon: Icon(Icons.key, color: AppTheme.gold))),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                          onPressed: _isLoading ? null : _changePassword,
                          icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(Icons.save),
                          label: const Text('ذخیره رمز جدید', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // حساب‌های بروکری
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance, color: AppTheme.gold),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('حساب‌های بروکری / صرافی', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))),
                          IconButton(icon: const Icon(Icons.add, color: AppTheme.gold, size: 20), onPressed: () => _showBrokerDialog()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_brokers.isEmpty)
                        const Text('حسابی ثبت نشده است.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13))
                      else
                        ..._brokers.map((b) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(backgroundColor: AppTheme.gold.withOpacity(0.2), child: const Icon(Icons.account_balance_wallet, color: AppTheme.gold, size: 20)),
                              title: Text(b['broker_name'], style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: Text('${b['account_type']} | موجودی: ${formatPrice(b['balance'])}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold, size: 20), onPressed: () => _showBrokerDialog(broker: b)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _deleteBroker(b['id'])),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // پشتیبان‌گیری
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.cloud_upload, color: AppTheme.gold), SizedBox(width: 8), Text('پشتیبان‌گیری', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 12),
                      const Text('از تمام اطلاعات خود نسخه پشتیبان تهیه کنید.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                          onPressed: _backupDatabase,
                          icon: const Icon(Icons.download),
                          label: const Text('دریافت فایل پشتیبان', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // حذف اطلاعات
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.delete_forever, color: Colors.red), SizedBox(width: 8), Text('حذف کامل اطلاعات', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 12),
                      const Text('این عمل تمام اطلاعات را برای همیشه پاک می‌کند.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: _resetDatabase,
                          icon: const Icon(Icons.delete),
                          label: const Text('حذف همه اطلاعات', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // خروج
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('خروج از حساب', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          onPressed: _logout,
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('خروج', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}