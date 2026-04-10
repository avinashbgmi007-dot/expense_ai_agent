import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('Union_Bank.pdf');
  final bytes = await file.readAsBytes();

  final allStrings = <String>[];

  int pos = _indexOfBytes(bytes, 'stream', 0);
  while (pos != -1) {
    int streamContentStart = -1;
    if (pos + 8 <= bytes.length && bytes[pos + 6] == 13 && bytes[pos + 7] == 10) {
      streamContentStart = pos + 8;
    } else if (pos + 7 <= bytes.length && bytes[pos + 6] == 10) {
      streamContentStart = pos + 7;
    } else {
      pos = _indexOfBytes(bytes, 'stream', pos + 6);
      continue;
    }

    int endIdx = _indexOfBytes(bytes, 'endstream', streamContentStart);
    if (endIdx == -1) break;

    try {
      List<int> streamBytes = bytes.sublist(streamContentStart, endIdx);
      List<int>? dec;
      try { dec = zlib.decode(streamBytes); } catch (_) {}
      if (dec == null) {
        try { dec = ZLibCodec(raw: true).decode(streamBytes); } catch (_) {}
      }
      if (dec != null) {
        final text = utf8.decode(dec, allowMalformed: true);
        for (final m in RegExp(r'\(([^)]*)\)').allMatches(text)) {
          var s = m.group(1)!;
          if (s.isEmpty) continue;
          int printable = s.codeUnits.where((c) => (c >= 32 && c <= 126)).length;
          if (printable > s.length * 0.5 && s.contains(RegExp(r'[A-Za-z0-9]'))) {
            allStrings.add(s);
          }
        }
      }
    } catch (_) {}

    pos = _indexOfBytes(bytes, 'stream', endIdx + 9);
  }

  // Now trace the Union Bank parser logic step by step for problem transactions
  final lines = allStrings.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  final dateRx = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');

  // Check all DD-MM-YYYY dates and their next 4 lines
  print('=== ALL DATE LINES WITH CONTEXT (next 4 lines) ===\n');
  for (int i = 0; i < lines.length; i++) {
    if (dateRx.hasMatch(lines[i])) {
      print('[$i] DATE: "${lines[i]}"');
      for (int j = 1; j <= 5 && i + j < lines.length; j++) {
        print('  +$j [$i+j]: "${lines[i + j]}"');
      }
      print('');
    }
  }

  // Check which dates match the transIdRx
  final transIdRxOld = RegExp(r'^[A-Z]?\d{5,}$', caseSensitive: false);
  final transIdRxNew = RegExp(r'^[A-Z0-9]{5,}$', caseSensitive: false);

  print('\n=== TRANSID CHECK ===');
  for (int i = 0; i < lines.length; i++) {
    if (dateRx.hasMatch(lines[i]) && i + 1 < lines.length) {
      final nextLine = lines[i + 1];
      final oldMatch = transIdRxOld.hasMatch(nextLine);
      final newMatch = transIdRxNew.hasMatch(nextLine);
      if (!oldMatch) {
        print('  OLD FAILS, NEW: $newMatch for "$nextLine" (after date "${lines[i]}")');
      }
    }
  }
}

int _indexOfBytes(List<int> bytes, String pattern, int start) {
  final units = pattern.codeUnits;
  for (int i = start; i <= bytes.length - units.length; i++) {
    bool match = true;
    for (int j = 0; j < units.length; j++) {
      if (bytes[i + j] != units[j]) { match = false; break; }
    }
    if (match) return i;
  }
  return -1;
}
