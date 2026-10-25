import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
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
  void initState() { super.initState(); _loadTerms(); }
  Future<void> _loadTerms() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllTerms();
    setState(() { _terms = data; _filteredTerms = data; _isLoading = false; });
  }

  void _filterTerms(String query) {
    setState(() {
      if (query.isEmpty) { _filteredTerms = _terms; } 
      else {
        _filteredTerms = _terms.where((t) => 
          (t['name'] ?? '').toLowerCase().contains(query.toLowerCase()) || 
          (t['description'] ?? '').toLowerCase().contains(query.toLowerCase()) || 
          (t['category'] ?? '').toLowerCase().contains(query.toLowerCase())
        ).toList();
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

  Future<void> _showTermDialog({Map<String, dynamic>? term}) async {
    final isEdit = term != null;
    final nameController = TextEditingController(text: term?['name']?.toString() ?? '');
    final descController = TextEditingController(text: term?['description']?.toString() ?? '');
    final categoryController = TextEditingController(text: term?['category']?.toString() ?? '');
    String? imagePathsJson = term?['image_path'];

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            List<String> currentImages = [];
            try { currentImages = imagePathsJson != null ? jsonDecode(imagePathsJson) : []; } catch(e) {}
            
            return AlertDialog(
              backgroundColor: AppTheme.cardBlack,
              title: Text(isEdit ? 'ویرایش اصطلاح' : 'افزودن اصطلاح جدید', style: const TextStyle(color: AppTheme.gold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام اصطلاح', prefixIcon: Icon(Icons.abc, color: AppTheme.gold))),
                    const SizedBox(height: 12),
                    TextField(controller: categoryController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'دسته‌بندی', prefixIcon: Icon(Icons.category, color: AppTheme.gold))),
                    const SizedBox(height: 12),
                    TextField(controller: descController, maxLines: 4, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'توضیحات کامل', prefixIcon: Icon(Icons.description, color: AppTheme.gold))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final List<XFile>? images = await _picker.pickMultiImage();
                        if (images != null && images.isNotEmpty) {
                          setStateDialog(() => currentImages = images.map((e) => e.path).toList());
                        }
                      },
                      icon: const Icon(Icons.image, color: AppTheme.gold),
                      label: const Text('انتخاب عکس (چندتایی)', style: TextStyle(color: AppTheme.textWhite)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cardBlack, side: const BorderSide(color: AppTheme.gold)),
                    ),
                    if (currentImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: currentImages.map((path) => GestureDetector(
                          onTap: () => _showFullScreenImage(ctx, path),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(width: 80, height: 80, child: Image.file(File(path), fit: BoxFit.cover)),
                          ),
                        )).toList(),
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
                      'image_path': currentImages.isNotEmpty ? jsonEncode(currentImages) : null,
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
            );
          },
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
    if (confirm == true) { await DatabaseHelper.instance.deleteTerm(id); _loadTerms(); }
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
              controller: _searchController, style: const TextStyle(color: AppTheme.textWhite),
              decoration: InputDecoration(hintText: 'جستجو...', prefixIcon: const Icon(Icons.search, color: AppTheme.gold), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppTheme.gold), onPressed: () { _searchController.clear(); _filterTerms(''); }) : null, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              onChanged: _filterTerms,
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppTheme.gold)) : _filteredTerms.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.menu_book, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('اصطلاحی یافت نشد', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))])) : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _filteredTerms.length,
              itemBuilder: (context, index) {
                final t = _filteredTerms[index];
                List<String> images = [];
                try { images = t['image_path'] != null ? jsonDecode(t['image_path']) : []; } catch(e) {}
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: images.isNotEmpty
                        ? GestureDetector(
                            onTap: () => _showFullScreenImage(context, images.first),
                            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 50, height: 50, child: Image.file(File(images.first), fit: BoxFit.cover))),
                          )
                        : const CircleAvatar(backgroundColor: Color(0xFF2A2A2A), child: Icon(Icons.abc, color: AppTheme.gold)),
                    title: Text(t['name'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((t['category'] ?? '').isNotEmpty) Text('دسته‌بندی: ${t['category']}', style: const TextStyle(color: AppTheme.gold, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(t['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textGrey)),
                        if (images.length > 1) Text('و ${images.length - 1} عکس دیگر', style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontStyle: FontStyle.italic)),
                      ],
                    ),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showTermDialog(term: t)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteTerm(t['id'])),
                    ]),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showTermDialog(), backgroundColor: AppTheme.gold, foregroundColor: Colors.black, icon: const Icon(Icons.add), label: const Text('افزودن اصطلاح')),
    );
  }
}