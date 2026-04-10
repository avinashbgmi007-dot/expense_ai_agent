import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('Union_Bank.pdf');
  final bytes = await file.readAsBytes();

  // Test: extract ONLY (text)Tj strings from all streams
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

        // Try pattern with Tj suffix first (standard PDF text operator)
        for (final m in RegExp(r'\(([^)]*)\)Tj').allMatches(text)) {
          var s = m.group(1)!;
          if (s.isEmpty) continue;
          int printable = s.codeUnits.where((c) => (c >= 32 && c <= 126)).length;
          if (printable > s.length * 0.5) {
            allStrings.add(s);
          }
        }
      }
    } catch (_) {}

    pos = _indexOfBytes(bytes, 'stream', endIdx + 9);
  }

  print('TOTAL strings (using (text)Tj pattern ONLY): ${allStrings.length}');
  for (int i = 0; i < allStrings.length; i++) {
    print('[$i] "${allStrings[i]}"');
  }

  // Also test the amount regex on these strings
  print('\n=== AMOUNT TEST ===');
  final amountRx = RegExp(r'^([\d,]+\.?\d*)\\?\((Dr|Cr)\\?$');
  final amountRx2 = RegExp(r'^([\d,]+\.?\d*)\\*?\((Dr|Cr)\\*?\)?\$');
  final amountRx3 = RegExp(r'^([\d,]+\.?\d*).*\((Dr|Cr\)');

  for (int i = 0; i < allStrings.length; i++) {
    final s = allStrings[i];
    if (s.contains('Dr') || s.contains('Cr')) {
      final m1 = amountRx.firstMatch(s);
      final m3 = amountRx3.firstMatch(s);
      print('  [$i] "$s" => Rx1: $m1, Rx3: $m3');
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
