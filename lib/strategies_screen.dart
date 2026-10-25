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
  void initState() { super.initState(); _loadStrategies(); }

  Future<void> _loadStrategies() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllStrategies();
    setState(() { _strategies = data; _filteredStrategies = data; _isLoading = false; });
  }

  void _filterStrategies(String query) {
    setState(() {
      if (query.isEmpty) { _filteredStrategies = _strategies; } 
      else {
        _filteredStrategies = _strategies.where((s) => (s['name'] ?? '').toLowerCase().contains(query.toLowerCase()) || (s['category'] ?? '').toLowerCase().contains(query.toLowerCase())).toList();
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
