import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
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
  void initState() { super.initState(); _loadStrategies(); }
  Future<void> _loadStrategies() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllStrategies();
    setState(() { _strategies = data; _filteredStrategies = data; _isLoading = false; });
  }

  void _filterStrategies(String query) {
    setState(() {
      if (query.isEmpty) { _filteredStrategies = _strategies; } 
      else { _filteredStrategies = _strategies.where((s) => (s['name'] ?? '').toLowerCase().contains(query.toLowerCase()) || (s['category'] ?? '').toLowerCase().contains(query.toLowerCase())).toList(); }
    });
  }

  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(panEnabled: true, boundaryMargin: const EdgeInsets.all(20), minScale: 0.5, maxScale: 4.0, child: Image.file(File(imagePath), fit: BoxFit.contain)),
        ),
      ),
    );
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
    String? imagePathsJson = strategy?['image_path'];

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            List<String> currentImages = parseImages(imagePathsJson);
            
            return AlertDialog(
              backgroundColor: AppTheme.cardBlack,
              title: Text(isEdit ? 'ویرایش استراتژی' : 'افزودن استراتژی جدید', style: const TextStyle(color: AppTheme.gold)),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                  TextField(controller: toolsController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'ابزارها', prefixIcon: Icon(Icons.build, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final List<XFile>? images = await _picker.pickMultiImage();
                      if (images != null && images.isNotEmpty) {
                        setStateDialog(() => currentImages = images.map((e) => e.path).toList());
                      }
                    },
                    icon: const Icon(Icons.image, color: AppTheme.gold),
                    label: const Text('انتخاب عکس چارت (چندتایی)', style: TextStyle(color: AppTheme.textWhite)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBlack, side: const BorderSide(color: AppTheme.gold)),
                  ),
                  if (currentImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: currentImages.map((path) => GestureDetector(
                        onTap: () => _showFullScreenImage(ctx, path),
                        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 80, height: 80, child: Image.file(File(path), fit: BoxFit.cover))),
                      )).toList(),
                    ),
                  ]
                ]),
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
                      'name': nameController.text.trim(), 'category': categoryController.text.trim(), 'description': descController.text.trim(),
                      'entry_conditions': entryController.text.trim(), 'exit_conditions': exitController.text.trim(),
                      'stop_loss': slController.text.trim(), 'take_profit': tpController.text.trim(), 'tools': toolsController.text.trim(),
                      'image_path': currentImages.isNotEmpty ? jsonEncode(currentImages) : null, 'created_at': getCurrentJalaliDateTime(),
                    };
                    if (isEdit) { await DatabaseHelper.instance.updateStrategy(strategy!['id'], strategyData); } 
                    else { await DatabaseHelper.instance.insertStrategy(strategyData); }
                    Navigator.pop(ctx);
                    _loadStrategies();
                  },
                  child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteStrategy(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(backgroundColor: AppTheme.cardBlack, title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)), content: const Text('آیا مطمئن هستید؟', style: TextStyle(color: AppTheme.textWhite)), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red)))])));
    if (confirm == true) { await DatabaseHelper.instance.deleteStrategy(id); _loadStrategies(); }
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
              controller: _searchController, style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(hintText: 'جستجو در نام یا دسته‌بندی...', prefixIcon: const Icon(Icons.search, color: AppTheme.gold), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterStrategies(''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onChanged: _filterStrategies,
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _filteredStrategies.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_graph, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('استراتژی‌ای یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredStrategies.length,
              itemBuilder: (context, index) {
                final s = _filteredStrategies[index];
                final List<String> images = parseImages(s['image_path']);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: images.isNotEmpty
                        ? GestureDetector(
                            onTap: () => _showFullScreenImage(context, images.first),
                            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 50, height: 50, child: Image.file(File(images.first), fit: BoxFit.cover))),
                          )
                        : const CircleAvatar(backgroundColor: Color(0xFF2A2A2A), child: Icon(Icons.auto_graph, color: AppTheme.gold)),
                    title: Text(s['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                    subtitle: Text(s['category'] ?? '', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if ((s['description'] ?? '').isNotEmpty) _infoRow('توضیحات', s['description']),
                          _infoRow('ورود', s['entry_conditions']),
                          _infoRow('خروج', s['exit_conditions']),
                          Row(children: [Expanded(child: _infoRow('حد ضرر', s['stop_loss'], color: Colors.red)), const SizedBox(width: 8), Expanded(child: _infoRow('حد سود', s['take_profit'], color: Colors.green))]),
                          _infoRow('ابزارها', s['tools']),
                          if (images.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: images.map((path) => GestureDetector(
                                onTap: () => _showFullScreenImage(context, path),
                                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 100, height: 100, child: Image.file(File(path), fit: BoxFit.cover))),
                              )).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showStrategyDialog(strategy: s)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteStrategy(s['id'])),
                          ]),
                        ]),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showStrategyDialog(), backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن استراتژی')),
    );
  }

  Widget _infoRow(String label, String? value, {Color color = AppTheme.textWhite}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label:', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(value ?? '-', style: TextStyle(color: color, fontSize: 13)),
      ]),
    );
  }
}