import 'dart:io';

void main() async {
  final contents = await File('Union_Bank.pdf').readAsBytes();
  final buffer = StringBuffer();
  for (final b in contents) {
    if ((b >= 32 && b <= 126) || b == 10 || b == 13 || b == 9) {
      buffer.write(String.fromCharCode(b));
    } else {
      buffer.write(' ');
    }
  }
  final text = buffer.toString().replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  
  // Find all transaction entries: date line followed by transaction data
  final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  
  // Print all lines near "BY CASH", "FRM", "ACCIDENTAL"
  for (int i = 0; i < lines.length; i++) {
    final lower = lines[i].toLowerCase();
    if (lower.contains('by') || lower.contains('frm') || lower.contains('accidental')) {
      print('[$i] "${lines[i]}"');
      // Print context
      for (int j = i - 2; j <= i + 2 && j >= 0 && j < lines.length; j++) {
        print('  $j: "${lines[j]}"');
      }
      print('');
    }
  }
  
  // Also check: what does the TransID look like for "ST6001150" type entries?
  for (int i = 0; i < lines.length; i++) {
    if (lines[i] == '30-07-2022') {
      print('Found date 30-07-2022, lines around it:');
      for (int j = i - 1; j < i + 8 && j < lines.length && j >= 0; j++) {
        print('  $j: "${lines[j]}"');
      }
      print('transId match for ST6001150: ${RegExp(r'^[ST]\d{5,}$', caseSensitive:false).hasMatch('ST6001150')}');
      print('transId match for AA289254: ${RegExp(r'^[AA]?\d{5,}$', caseSensitive:false).hasMatch('AA289254')}');
    }
  }
}
