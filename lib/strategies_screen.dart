import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';

class StrategiesScreen extends StatefulWidget {
  const StrategiesScreen({super.key});

  @override
  State<StrategiesScreen> createState() => _StrategiesScreenState();
}

class _StrategiesScreenState extends State<StrategiesScreen> {
  List<Map<String, dynamic>> _strategies = [];
  List<Map<String, dynamic>> _filteredStrategies = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadStrategies();
  }

  Future<void> _loadStrategies() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllStrategies();
    setState(() {
      _strategies = data;
      _filteredStrategies = data;
      _isLoading = false;
    });
  }

  void _filterStrategies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStrategies = _strategies;
      } else {
        _filteredStrategies = _strategies.where((s) =>
          (s['name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
          (s['category'] ?? '').toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _showStrategyDialog({Map<String, dynamic>? strategy}) async {
    final isEdit = strategy != null;
    final nameController = TextEditingController(text: strategy?['name']?.toString() ?? '');
    final categoryController = TextEditingController(text: strategy?['category']?.toString() ?? '');
    final descController = TextEditingController(text: strategy?['description']?.toString() ?? '');
    final entryController = TextEditingController(text: strategy?['entry_conditions']?.toString() ?? '');
    final exitController = TextEditingController(text: strategy?['exit_conditions']?.toString() ?? '');
    final slController = TextEditingController(text: strategy?['stop_loss']?.toString() ?? '');
    final tpController = TextEditingController(text: strategy?['take_profit']?.toString() ?? '');
    final toolsController = TextEditingController(text: strategy?['tools']?.toString() ?? '');
    String? imagePath = strategy?['image_path'];

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش استراتژی' : 'افزودن استراتژی جدید', style: const TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام استراتژی', prefixIcon: Icon(Icons.auto_graph, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: categoryController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'دسته‌بندی', prefixIcon: Icon(Icons.category, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: descController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'توضیحات کلی', prefixIcon: Icon(Icons.description, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: entryController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شرایط ورود', prefixIcon: Icon(Icons.login, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: exitController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'شرایط خروج', prefixIcon: Icon(Icons.logout, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: slController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'حد ضرر (SL)', prefixIcon: Icon(Icons.stop, color: Colors.red)))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: tpController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'حد سود (TP)', prefixIcon: Icon(Icons.flag, color: Colors.green)))),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: toolsController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'ابزارها (مثال: RSI, حمایت)', prefixIcon: Icon(Icons.build, color: AppTheme.gold))),
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
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام استراتژی الزامی است'), backgroundColor: Colors.red));
                    return;
                  }
                  final strategyData = {
                    'name': nameController.text.trim(),
                    'category': categoryController.text.trim(),
                    'description': descController.text.trim(),
                    'entry_conditions': entryController.text.trim(),
                    'exit_conditions': exitController.text.trim(),
                    'stop_loss': slController.text.trim(),
                    'take_profit': tpController.text.trim(),
                    'tools': toolsController.text.trim(),
                    'image_path': imagePath,
                    'created_at': getCurrentJalaliDateTime(),
                  };
                  if (isEdit) {
                    await DatabaseHelper.instance.updateStrategy(strategy!['id'], strategyData);
                  } else {
                    await DatabaseHelper.instance.insertStrategy(strategyData);
                  }
                  Navigator.pop(ctx);
                  _loadStrategies();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteStrategy(int id) async {
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
      await DatabaseHelper.instance.deleteStrategy(id);
      _loadStrategies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('استراتژی‌ها'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadStrategies)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'جستجو در نام یا دسته‌بندی...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterStrategies(''); })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filterStrategies,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _filteredStrategies.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_graph, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('استراتژی‌ای یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredStrategies.length,
                        itemBuilder: (context, index) {
                          final s = _filteredStrategies[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: s['image_path'] != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(s['image_path']!), width: 50, height: 50, fit: BoxFit.cover))
                                  : CircleAvatar(backgroundColor: AppTheme.gold.withOpacity(0.2), child: Icon(Icons.auto_graph, color: AppTheme.gold)),
                              title: Text(s['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: Text(s['category'] ?? '', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if ((s['description'] ?? '').isNotEmpty) _infoRow('توضیحات', s['description']),
                                      _infoRow('ورود', s['entry_conditions']),
                                      _infoRow('خروج', s['exit_conditions']),
                                      Row(children: [
                                        Expanded(child: _infoRow('حد ضرر', s['stop_loss'], color: Colors.red)),
                                        const SizedBox(width: 8),
                                        Expanded(child: _infoRow('حد سود', s['take_profit'], color: Colors.green)),
                                      ]),
                                      _infoRow('ابزارها', s['tools']),
                                      if (s['image_path'] != null) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(s['image_path']!), width: double.infinity, fit: BoxFit.cover)),
                                      ],
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showStrategyDialog(strategy: s)),
                                          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteStrategy(s['id'])),
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
        onPressed: () => _showStrategyDialog(),
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('افزودن استراتژی'),
      ),
    );
  }

  Widget _infoRow(String label, String? value, {Color color = AppTheme.textWhite}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(value ?? '-', style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }
}