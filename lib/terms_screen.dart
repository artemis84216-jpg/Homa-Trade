import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database_helper.dart';
import 'app_utils.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  List<Map<String, dynamic>> _terms = [];
  List<Map<String, dynamic>> _filteredTerms = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  Future<void> _loadTerms() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllTerms();
    setState(() {
      _terms = data;
      _filteredTerms = data;
      _isLoading = false;
    });
  }

  void _filterTerms(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTerms = _terms;
      } else {
        _filteredTerms = _terms.where((t) =>
          (t['name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
          (t['description'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
          (t['category'] ?? '').toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _showTermDialog({Map<String, dynamic>? term}) async {
    final isEdit = term != null;
    final nameController = TextEditingController(text: term?['name']?.toString() ?? '');
    final descController = TextEditingController(text: term?['description']?.toString() ?? '');
    final categoryController = TextEditingController(text: term?['category']?.toString() ?? '');
    String? imagePath = term?['image_path'];

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش اصطلاح' : 'افزودن اصطلاح جدید', style: const TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'نام اصطلاح', prefixIcon: Icon(Icons.abc, color: AppTheme.gold)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: categoryController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'دسته‌بندی (مثال: پرایس اکشن)', prefixIcon: Icon(Icons.category, color: AppTheme.gold)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    style: const TextStyle(color: AppTheme.textWhite),
                    decoration: const InputDecoration(labelText: 'توضیحات کامل', prefixIcon: Icon(Icons.description, color: AppTheme.gold)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) setStateDialog(() => imagePath = image.path);
                    },
                    icon: const Icon(Icons.image, color: AppTheme.gold),
                    label: Text(imagePath != null ? 'تغییر عکس' : 'انتخاب عکس', style: const TextStyle(color: AppTheme.textWhite)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBlack, side: const BorderSide(color: AppTheme.gold)),
                  ),
                  if (imagePath != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(imagePath!), height: 100, width: double.infinity, fit: BoxFit.cover),
                    ),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نام اصطلاح الزامی است'), backgroundColor: Colors.red));
                    return;
                  }
                  final termData = {
                    'name': nameController.text.trim(),
                    'category': categoryController.text.trim(),
                    'description': descController.text.trim(),
                    'image_path': imagePath,
                    'created_at': getCurrentJalaliDateTime(),
                  };
                  if (isEdit) {
                    await DatabaseHelper.instance.updateTerm(term!['id'], termData);
                  } else {
                    await DatabaseHelper.instance.insertTerm(termData);
                  }
                  Navigator.pop(ctx);
                  _loadTerms();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTerm(int id) async {
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
      await DatabaseHelper.instance.deleteTerm(id);
      _loadTerms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('اصطلاحات ترید'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadTerms)]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'جستجو در نام، دسته‌بندی یا توضیحات...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterTerms(''); })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filterTerms,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _filteredTerms.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.menu_book, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('اصطلاحی یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredTerms.length,
                        itemBuilder: (context, index) {
                          final t = _filteredTerms[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: t['image_path'] != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(t['image_path']!), width: 50, height: 50, fit: BoxFit.cover))
                                  : CircleAvatar(backgroundColor: AppTheme.gold.withOpacity(0.2), child: Icon(Icons.abc, color: AppTheme.gold)),
                              title: Text(t['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if ((t['category'] ?? '').isNotEmpty) Text('دسته‌بندی: ${t['category']}', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(t['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textGrey)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showTermDialog(term: t)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTerm(t['id'])),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTermDialog(),
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('افزودن اصطلاح'),
      ),
    );
  }
}