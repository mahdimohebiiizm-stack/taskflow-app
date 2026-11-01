import 'persian_number_formatter.dart';

/// ابزار استاندارد تبدیل تاریخ میلادی به تاریخ هجری شمسی (جلالی)
abstract final class JalaliDateFormatter {
  static const List<String> monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  static const List<String> weekDayNames = [
    'شنبه',
    'یکشنبه',
    'دوشنبه',
    'سه‌شنبه',
    'چهارشنبه',
    'پنجشنبه',
    'جمعه',
  ];

  /// تبدیل دقیق تاریخ میلادی به سال، ماه و روز جلالی
  static ({int year, int month, int day}) toJalali(DateTime date) {
    const gDaysInMonth = <int>[
      31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
    ];
    const jDaysInMonth = <int>[
      31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29
    ];

    final int gy = date.year - 1600;
    final int gm = date.month - 1;
    final int gd = date.day - 1;

    int gDayNo = 365 * gy +
        ((gy + 3) ~/ 4) -
        ((gy + 99) ~/ 100) +
        ((gy + 399) ~/ 400);

    for (int i = 0; i < gm; ++i) {
      gDayNo += gDaysInMonth[i];
    }
    if (gm > 1 && ((gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0))) {
      gDayNo++;
    }
    gDayNo += gd;

    int jDayNo = gDayNo - 79;
    final int jNp = jDayNo ~/ 12053;
    jDayNo %= 12053;

    int jy = 979 + 33 * jNp + 4 * (jDayNo ~/ 1461);
    jDayNo %= 1461;

    if (jDayNo >= 366) {
      jy += (jDayNo - 1) ~/ 365;
      jDayNo = (jDayNo - 1) % 365;
    }

    int jm = 0;
    while (jm < 11 && jDayNo >= jDaysInMonth[jm]) {
      jDayNo -= jDaysInMonth[jm];
      jm++;
    }
    final int jd = jDayNo + 1;
    return (year: jy, month: jm + 1, day: jd);
  }

  /// فرمت عددی جلالی با اعداد فارسی: مثلاً «۱۴۰۵/۰۷/۲۶»
  static String formatDate(DateTime date, {String separator = '/'}) {
    final j = toJalali(date);
    final y = toPersianDigits(j.year.toString().padLeft(4, '0'));
    final m = toPersianDigits(j.month.toString().padLeft(2, '0'));
    final d = toPersianDigits(j.day.toString().padLeft(2, '0'));
    return '$y$separator$m$separator$d';
  }

  /// نام ماه جلالی (۱-۱۲)
  static String monthName(int month) {
    if (month < 1 || month > 12) return '';
    return monthNames[month - 1];
  }

  /// فرمت کوتاه: مثلاً «۲۶ مهر»
  static String formatShort(DateTime date) {
    final j = toJalali(date);
    return '${toPersianDigits(j.day.toString())} ${monthName(j.month)}';
  }

  /// فرمت ماه و سال: مثلاً «مهر ۱۴۰۵»
  static String formatMonthYear(DateTime date) {
    final j = toJalali(date);
    return '${monthName(j.month)} ${toPersianDigits(j.year.toString())}';
  }

  /// فرمت کامل همراه با نام روز هفته: مثلاً «شنبه ۲۶ مهر»
  static String formatFull(DateTime date) {
    final weekdayFa = switch (date.weekday) {
      DateTime.saturday => 'شنبه',
      DateTime.sunday => 'یکشنبه',
      DateTime.monday => 'دوشنبه',
      DateTime.tuesday => 'سه‌شنبه',
      DateTime.wednesday => 'چهارشنبه',
      DateTime.thursday => 'پنجشنبه',
      DateTime.friday => 'جمعه',
      _ => '',
    };
    final short = formatShort(date);
    return weekdayFa.isEmpty ? short : '$weekdayFa $short';
  }

  /// فرمت نسبی هوشمند: «امروز (۲۶ مهر)»، «فردا (۲۷ مهر)» یا «۲۶ مهر»
  static String formatRelativeJalali(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;

    final short = formatShort(date);
    if (isToday) {
      return 'امروز ($short)';
    }
    if (isTomorrow) {
      return 'فردا ($short)';
    }
    return short;
  }
}
