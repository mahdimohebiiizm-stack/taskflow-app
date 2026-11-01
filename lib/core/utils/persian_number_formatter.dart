/// ابزار کمکی تبدیل ارقام انگلیسی به فارسی و فرمت‌بندی اعداد
abstract final class PersianNumberFormatter {
  static const List<String> _englishDigits = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  static const List<String> _persianDigits = [
    '۰',
    '۱',
    '۲',
    '۳',
    '۴',
    '۵',
    '۶',
    '۷',
    '۸',
    '۹',
  ];

  /// تمام ارقام انگلیسی و عربی موجود در رشته ورودی را به ارقام استاندارد فارسی تبدیل می‌کند.
  static String toPersianDigits(String input) {
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(_englishDigits[i], _persianDigits[i]);
    }
    return result;
  }

  /// ارقام فارسی یا عربی واردشده توسط کاربر در فیلدهای ورودی را به ارقام انگلیسی استاندارد
  /// برای تبدیل امن به عدد صحیح تبدیل می‌کند.
  static String toEnglishDigits(String input) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(_persianDigits[i], _englishDigits[i]);
      result = result.replaceAll(arabicDigits[i], _englishDigits[i]);
    }
    return result;
  }
}

/// تابع میان‌بر سراسری برای تبدیل سریع هر رشته به ارقام فارسی
String toPersianDigits(String input) =>
    PersianNumberFormatter.toPersianDigits(input);
