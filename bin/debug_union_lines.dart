import 'dart:io';
import 'dart:convert';

void main() async {
  final bytes = await File('Union_Bank.pdf').readAsBytes();
  final text = _extractRawReadableText(bytes);
  final allLines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  
  print('Total lines: ${allLines.length}');
  
  // Find lines containing "BY" (transaction descriptions like "BY CASH" or "BY <account>")
  print('\n=== LINES containing "BY" ===');
  for (int i = 0; i < allLines.length; i++) {
    final lower = allLines[i].trim().toLowerCase();
    if ((lower == 'by' || lower == 'by cash' || lower.startsWith('by ') || lower.startsWith('by c')) &&
        !lower.contains('by ')) {
      // Exact matches or near matches
      print('[$i] "${allLines[i].trim()}"');
    }
  }
  
  // Also look for lines around "AA289254" - the BY CASH transaction from 17-01-2022
  print('\n=== Lines around BY CASH transactions ===');
  for (int i = 0; i < allLines.length; i++) {
    if (allLines[i].trim() == '17-01-2022' || allLines[i].trim() == '18-01-2022' ||
        allLines[i].trim() == '05-01-2022' || allLines[i].trim() == '30-07-2022') {
      print('\n--- Date found at index $i ---');
      for (int j = i; j < i + 6 && j < allLines.length; j++) {
        print('  [$j] "${allLines[j]}"');
      }
    }
  }
}

String _extractRawReadableText(List<int> bytes) {
  final buffer = StringBuffer();
  for (int i = 0; i < bytes.length; i++) {
    final code = bytes[i];
    if ((code >= 32 && code <= 126) || code == 10 || code == 13) {
      buffer.write(String.fromCharCode(code));
    } else {
      buffer.write(' ');
    }
  }
  var text = buffer.toString();
  text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  text = text.replaceAll(RegExp(r'\n\s*\n'), '\n');
  return text.trim();
}
