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

  // تابع نمایش تمام صفحه عکس
  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
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
            title: Text(isEdit ? 'ویرایش اصطلاح' : 'افزودن اصطلاح جدید', style: const