import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'terms_screen.dart';
import 'strategies_screen.dart';
import 'compound_screen.dart';
import 'backtests_screen.dart';
import 'watchlist_screen.dart';
import 'app_utils.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _dailyTip = '';

  @override
  void initState() {
    super.initState();
    _dailyTip = getRandomDailyTip();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Homa_Trade'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings, color: AppTheme.gold), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // نکته روزانه
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.gold.withOpacity(0.3), AppTheme.gold.withOpacity(0.1)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.lightbulb, color: AppTheme.gold), SizedBox(width: 8), Text('نکته روزانه ترید', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16))]),
                    const SizedBox(height: 12),
                    Text(_dailyTip, style: const TextStyle(color: AppTheme.textWhite, fontSize: 15, height: 1.6)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('بخش‌های اصلی', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCard(Icons.menu_book, 'اصطلاحات ترید', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()))),
                  _buildCard(Icons.strategy, 'استراتژی‌ها', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StrategiesScreen()))),
                  _buildCard(Icons.calculate, 'سود مرکب', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompoundScreen()))),
                  _buildCard(Icons.history_edu, 'بک‌تست‌ها', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BacktestsScreen()))),
                  _buildCard(Icons.visibility, 'واچ‌لیست', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchlistScreen()))),
                  _buildCard(Icons.account_balance, 'حساب‌های من', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(IconData icon, String title, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppTheme.gold),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
          ],
        ),
      ),
    );
  }
}