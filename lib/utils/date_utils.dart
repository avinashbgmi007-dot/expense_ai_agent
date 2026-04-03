// utils/date_utils.dart
String formatDate(String inputDate) {
  // Handle different date formats
  final RegExp ddMmYy = RegExp(r'(\d{2})/(\d{2})/(\d{2})');
  final RegExp yyyyMmDd = RegExp(r'(\d{4})-(\d{2})-(\d{2})');
  final RegExp mmDdYyyy = RegExp(r'(\d{2})-(\d{2})-(\d{4})');

  if (ddMmYy.hasMatch(inputDate)) {
    final matches = ddMmYy.firstMatch(inputDate)!;
    final day = int.parse(matches.group(1)!);
    final month = int.parse(matches.group(2)!);
    final year = int.parse(matches.group(3)!);
    return '$year-$month-$day';
  } else if (yyyyMmDd.hasMatch(inputDate)) {
    final matches = yyyyMmDd.firstMatch(inputDate)!;
    return matches.group(1)!;
  } else if (mmDdYyyy.hasMatch(inputDate)) {
    final matches = mmDdYyyy.firstMatch(inputDate)!;
    final day = int.parse(matches.group(2)!);
    final month = int.parse(matches.group(1)!);
    final year = int.parse(matches.group(3)!);
    return '$year-$month-$day';
  }

  return inputDate;
}
