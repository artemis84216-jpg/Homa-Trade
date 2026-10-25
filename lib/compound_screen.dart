import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';
import 'app_utils.dart';

class CompoundScreen extends StatefulWidget {
  const CompoundScreen({super.key});

  @override
  State<CompoundScreen> createState() => _CompoundScreenState();
}

class _CompoundScreenState extends State<CompoundScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllCompoundPlans();
    setState(() {
      _plans = data;
      _isLoading = false;
    });
  }

  Future<void> _showPlanDialog({Map<String, dynamic>? plan}) async {
    final isEdit = plan != null;
    final nameController = TextEditingController(text: plan?['name']?.toString() ?? '');
    final capitalController = TextEditingController(text: (plan?['initial_capital'] ?? 0).toString());
    final percentController = TextEditingController(text: (plan?['daily_target_percent'] ?? 0).toString());
    final daysController = TextEditingController(text: (plan?['total_days'] ?? 30).toString());

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: Text(isEdit ? 'ویرایش برنامه' : 'برنامه سود مرکب جدید', style: const TextStyle(color: AppTheme.gold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'نام برنامه', prefixIcon: Icon(Icons.title, color: AppTheme.gold))),
                const SizedBox(height: 12),
                TextField(controller: capitalController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'سرمایه اولیه (تتر / USDT)', prefixIcon: Icon(Icons.account_balance_wallet, color: AppTheme.gold))),
                const SizedBox(height: 12),
                TextField(controller: percentController, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'درصد سود روزانه هدف', prefixIcon: Icon(Icons.percent, color: AppTheme.gold))),
                const SizedBox(height: 12),
                TextField(controller: daysController, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textWhite), decoration: const InputDecoration(labelText: 'تعداد کل روزها', prefixIcon: Icon(Icons.calendar_today, color: AppTheme.gold))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف', style: TextStyle(color: AppTheme.textGrey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
              onPressed: () async {
                final capital = double.tryParse(toEnglishDigits(capitalController.text.replaceAll(',', ''))) ?? 0;
                final percent = double.tryParse(percentController.text) ?? 0;
                final days = int.tryParse(daysController.text) ?? 30;

                final planData = {
                  'name': nameController.text.trim(),
                  'initial_capital': capital,
                  'daily_target_percent': percent,
                  'total_days': days,
                  'created_at': getCurrentJalaliDateTime(),
                };

                int planId;
                if (isEdit) {
                  planId = plan!['id'];
                  await DatabaseHelper.instance.updateCompoundPlan(planId, planData);
                  final oldDays = await DatabaseHelper.instance.getCompoundDaysByPlan(planId);
                  for (var d in oldDays) {
                    await DatabaseHelper.instance.deleteCompoundDay(d['id']);
                  }
                } else {
                  planId = await DatabaseHelper.instance.insertCompoundPlan(planData);
                }

                double currentTarget = capital;
                for (int i = 1; i <= days; i++) {
                  currentTarget = currentTarget * (1 + (percent / 100));
                  await DatabaseHelper.instance.insertCompoundDay({
                    'plan_id': planId,
                    'day_number': i,
                    'target_amount': currentTarget,
                    'achieved': 0,
                    'actual_amount': 0,
                    'date': '',
                    'notes': '',
                  });
                }

                Navigator.pop(ctx);
                _loadPlans();
              },
              child: Text(isEdit ? 'ذخیره' : 'ایجاد برنامه', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePlan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppTheme.cardBlack,
          title: const Text('تایید حذف', style: TextStyle(color: AppTheme.gold)),
          content: const Text('آیا مطمئن هستید؟ تمام روزهای این برنامه نیز حذف خواهند شد.', style: TextStyle(color: AppTheme.textWhite)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (confirm == true) {
      final days = await DatabaseHelper.instance.getCompoundDaysByPlan(id);
      for (var d in days) {
        await DatabaseHelper.instance.deleteCompoundDay(d['id']);
      }
      await DatabaseHelper.instance.deleteCompoundPlan(id);
      _loadPlans();
    }
  }

  Future<void> _viewPlanDetails(Map<String, dynamic> plan) async {
    final days = await DatabaseHelper.instance.getCompoundDaysByPlan(plan['id']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBlack,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(plan['name'], style: const TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(color: AppTheme.gold),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final d = days[index];
                    final isAchieved = d['achieved'] == 1;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAchieved ? AppTheme.green.withOpacity(0.2) : AppTheme.textGrey.withOpacity(0.2),
                        child: Icon(isAchieved ? Icons.check : Icons.circle_outlined, color: isAchieved ? AppTheme.green : AppTheme.textGrey),
                      ),
                      title: Text('روز ${toPersianDigits(d['day_number'].toString())}', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                      subtitle: Text('هدف: ${d['target_amount'].toStringAsFixed(2)} تتر', style: const TextStyle(color: AppTheme.textGrey)),
                      trailing: Checkbox(
                        value: isAchieved,
                        activeColor: AppTheme.green,
                        onChanged: (val) async {
                          await DatabaseHelper.instance.updateCompoundDay(d['id'], {
                            'achieved': val == true ? 1 : 0,
                            'date': val == true ? getCurrentJalaliDate() : '',
                          });
                          Navigator.pop(ctx);
                          _viewPlanDetails(plan);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('سود مرکب (تتر)'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _plans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate, size: 80, color: AppTheme.textGrey),
                      const SizedBox(height: 16),
                      const Text('برنامه‌ای تعریف نشده است', style: TextStyle(fontSize: 18, color: AppTheme.textGrey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _plans.length,
                  itemBuilder: (context, index) {
                    final p = _plans[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: AppTheme.gold.withOpacity(0.2), child: const Icon(Icons.trending_up, color: AppTheme.gold)),
                        title: Text(p['name'], style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                        subtitle: Text('سرمایه: ${p['initial_capital']} تتر | سود روزانه: ${p['daily_target_percent']}٪\nتعداد روز: ${toPersianDigits(p['total_days'].toString())}', style: const TextStyle(color: AppTheme.textGrey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.visibility, color: AppTheme.gold), onPressed: () => _viewPlanDetails(p)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePlan(p['id'])),
                          ],
                        ),
                        onTap: () => _viewPlanDetails(p),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanDialog(),
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('برنامه جدید'),
      ),
    );
  }
}