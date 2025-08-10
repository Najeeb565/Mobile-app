import 'package:intl/intl.dart';

class DateUtilsX {
  static String formatYmd(DateTime dt) => DateFormat('yyyy-MM-dd').format(DateTime(dt.year, dt.month, dt.day));
}