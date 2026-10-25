import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllWatchlist();
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  Future<void> _showItemDialog({Map<String, dynamic>? item}) async {
    final isEdit = item != null;
    final symbolController = TextEditingController(text: item?['symbol']?.toString() ?? '');
    final reasonController = TextEditingController(text: item?['reason']?.toString() ?? '');
    final targetController = TextEditingController(text: (item?['target_price'] ?? 0).toString());
    final stopController = TextEditingController(text: (item?['stop_price'] ?? 0).toString());
    final notesController = TextEditingController(text: item?['notes']?.toString() ?? '');
    int isActive = item?['is_active'] ?? 1;

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: AppTheme.cardBlack,
            title: Text(isEdit ? 'ویرایش' : 'افزودن به واچ‌لیست', style: const TextStyle(color: AppTheme.gold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: symbolController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نماد (مثال: XAUUSD)', prefixIcon: Icon(Icons.currency_exchange, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  TextField(controller: reasonController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'دلیل زیر نظر گرفتن', prefixIcon: Icon(Icons.lightbulb, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: TextField(controller: targetController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'قیمت هدف (TP)', prefixIcon: Icon(Icons.flag, color: AppTheme.green)))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: stopController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'حد ضرر (SL)', prefixIcon: Icon(Icons.stop, color: AppTheme.red)))),
                  ]),
                  const SizedBox(height: 12),
                  TextField(controller: notesController, maxLines: 2, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'یادداشت', prefixIcon: Icon(Icons.notes, color: AppTheme.gold))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(value: isActive == 1, activeColor: AppTheme.green, onChanged: (val) => setStateDialog(() => isActive = val == true ? 1 : 0)),
                      const Text('فعال باشد', style: TextStyle(color: AppTheme.textWhite)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                onPressed: () async {
                  final itemData = {
                    'symbol': symbolController.text.trim(),
                    'reason': reasonController.text.trim(),
                    'target_price': double.tryParse(targetController.text) ?? 0,
                    'stop_price': double.tryParse(stopController.text) ?? 0,
                    'notes': notesController.text.trim(),
                    'is_active': isActive,
                    'created_at': getCurrentJalaliDateTime(),
                  };
                  if (isEdit) {
                    await DatabaseHelper.instance.updateWatchlist(item!['id'], itemData);
                  } else {
                    await DatabaseHelper.instance.insertWatchlist(itemData);
                  }
                  Navigator.pop(ctx);
                  _loadItems();
                },
                child: Text(isEdit ? 'ذخیره' : 'افزودن', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
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
      await DatabaseHelper.instance.deleteWatchlist(id);
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('واچ‌لیست'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.refresh, color: AppTheme.gold), onPressed: _loadItems)]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _items.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.visibility, size: 80, color: AppTheme.textGrey), const SizedBox(height: 16), Text('لیست خالی است', style: TextStyle(fontSize: 18, color: AppTheme.textGrey))]))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final w = _items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: AppTheme.gold.withOpacity(0.2), child: const Icon(Icons.visibility, color: AppTheme.gold)),
                        title: Text(w['symbol'], style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('دلیل: ${w['reason']}', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                            if ((w['target_price'] ?? 0) > 0) Text('TP: ${w['target_price']} | SL: ${w['stop_price']}', style: const TextStyle(color: AppTheme.textYellow, fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: AppTheme.gold), onPressed: () => _showItemDialog(item: w)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(w['id'])),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showItemDialog(),
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('افزودن نماد'),
      ),
    );
  }
}