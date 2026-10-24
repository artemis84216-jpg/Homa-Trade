import 'package:flutter/material.dart';
import 'app_utils.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(title: const Text('اصطلاحات ترید'), centerTitle: true),
      body: const Center(child: Text('در فاز ۲ تکمیل می‌شود', style: TextStyle(color: AppTheme.textGrey))),
    );
  }
}