import 'package:flutter/material.dart';
import 'app_utils.dart';

class BacktestsScreen extends StatelessWidget {
  const BacktestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('بک‌تست‌ها'), centerTitle: true),
      body: const Center(child: Text('در فاز ۳ تکمیل می‌شود', style: TextStyle(color: AppTheme.textGrey))),
    );
  }
}