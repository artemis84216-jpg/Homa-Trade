import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class AppTheme {
  static const Color backgroundBlack = Color(0xFF0A0A0A);
  static const Color cardBlack = Color(0xFF1A1A1A);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFFFA000);
  static const Color textWhite = Colors.white;
  static const Color textYellow = Color(0xFFFFEB3B);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFE53935);
  static const Color blue = Color(0xFF2196F3);
  
  static ThemeData get darkGoldTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: gold,
      scaffoldBackgroundColor: backgroundBlack,
      colorScheme: const ColorScheme.dark(primary: gold, secondary: goldDark, surface: cardBlack, onPrimary: Colors.black, onSurface: textWhite),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: gold, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gold, width: 1)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF444444), width: 1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: gold, width: 2)),
        labelStyle: const TextStyle(color: textGrey), hintStyle: const TextStyle(color: Color(0xFF666666)),
      ),
    );
  }
}

String toPersianDigits(String input) {
  return input.replaceAll('0', '۰').replaceAll('1', '۱').replaceAll('2', '۲').replaceAll('3', '۳').replaceAll('4', '۴').replaceAll('5', '۵').replaceAll('6', '۶').replaceAll('7', '۷').replaceAll('8', '۸').replaceAll('9', '۹');
}

String toEnglishDigits(String input) {
  const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (int i = 0; i < 10; i++) {
    input = input.replaceAll(persian[i], i.toString()).replaceAll(arabic[i], i.toString());
  }
  return input;
}

String formatPrice(dynamic price) {
  if (price == null) return '۰';
  final num priceNum = price is int ? price : (price is double ? price.toInt() : 0);
  String formatted = priceNum.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  return toPersianDigits(formatted);
}

String formatNumber(num number) => toPersianDigits(number.toString());

String getCurrentJalaliDate() {
  final now = Jalali.now();
  return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}';
}

String getCurrentJalaliDateTime() {
  final now = Jalali.now();
  return '${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}

class CommaSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String cleanText = toEnglishDigits(newValue.text.replaceAll(',', ''));
    if (cleanText.isEmpty) return newValue;
    final intVal = int.tryParse(cleanText);
    if (intVal == null) return oldValue;
    final formatted = intVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}

// لیست نکات روزانه ترید
const List<String> dailyTradingTips = [
  '🎯 قبل از ورود به معامله، حتماً حد ضرر را مشخص کن.',
  '💰 هرگز بیشتر از ۲٪ سرمایه را در یک معامله ریسک نکن.',
  '🧘 آرامش ذهن، مهم‌ترین ابزار تریدر است.',
  '📊 معامله بر اساس احساسات = فاجعه.',
  '📝 هر معامله‌ای را در ژورنال ثبت کن، حتی زیان‌ها.',
  '⏰ صبر کردن برای ستاپ مناسب، بخشی از استراتژی است.',
  '🚫 انتقام از بازار بعد از ضرر، بدترین تصمیم است.',
  '✅ فقط با ستاپ‌های A+ وارد شو، نه هر فرصتی.',
  '📈 روند دوست توست، هرگز خلاف جهت آن ترید نکن.',
  '🎓 یادگیری هرگز متوقف نمی‌شود، حتی پس از سال‌ها.',
  '💎 سود کوچک مستمر بهتر از سود بزرگ یکباره است.',
  '🔍 همیشه قبل از ترید، تقاطع زمانی‌ها را بررسی کن.',
  '⚖️ نسبت ریسک به ریوارد حداقل ۱:۲ باشد.',
  '🛑 اگر به حد ضرر رسیدی، بدون تردید خارج شو.',
  '📉 ضرر بخشی از بازی است، آن را بپذیر.',
  '🎯 اهداف واقع‌بینانه داشته باش، نه رویایی.',
  '💪 نظم و انضباط، کلید موفقیت بلندمدت است.',
  '🌊 بازار همیشه حق دارد، تو باید با آن همراه شوی.',
  '📚 از اشتباهاتت یاد بگیر و تکرارشان نکن.',
  '🧠 ذهنیت رشد داشته باش، نه ذهنیت ثابت.',
  '⚡ از ترید بیش از حد (Overtrading) پرهیز کن.',
  '🎪 بازار یک سیرک نیست، یک کسب‌وکار جدی است.',
  '💡 هر روز یک درس جدید از بازار یاد بگیر.',
  '🔒 اطلاعات حساب‌هایت را محرمانه نگه دار.',
  '🎨 چارت را ساده نگه دار، شلوغی گیج‌کننده است.',
  '🏆 موفقیت در ترید، نتیجه عادت‌های کوچک روزانه است.',
  '⏳ به بازار زمان بده، عجله نکن.',
  '🎯 قبل از ورود، دلیل منطقی داشته باش.',
  '💭 با خودت صادق باش، به خصوص در ضررها.',
  '🌟 تریدر موفق، یک مدیریت ریسک عالی است.',
];

String getRandomDailyTip() {
  final now = DateTime.now();
  final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
  return dailyTradingTips[dayOfYear % dailyTradingTips.length];
}