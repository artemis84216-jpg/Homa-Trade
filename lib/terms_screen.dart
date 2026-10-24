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
                  TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام اصطلاح', prefixIcon: Icon(Icons.abc, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: categoryController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'دسته‌بندی (مثال: پرایس اکشن)', prefixIcon: Icon(Icons.category, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: descController, maxLines: 4, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'توضیحات کامل', prefixIcon: Icon(Icons.description, color: AppTheme.gold))),
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
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(imagePath!), height: 100, width: double.infinity