import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('Union_Bank.pdf');
  final bytes = await file.readAsBytes();

  // Simulate the exact _extractAllText → _parseAllTransactions flow
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
        for (final m in RegExp(r'\(([^\)]*)\)').allMatches(text)) {
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

  print('Total strings: ${allStrings.length}');
  for (int i = 0; i < allStrings.length; i++) {
    print('[$i] "${allStrings[i]}"');
  }

  // Now parse line by line as the Union Bank parser does
  print('\n=== PARSING AS UNION BANK FORMAT ===');
  final lines = allStrings.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  int i = 0;
  final dateRx = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
  final amountDrRx = RegExp(r'^([\d,]+\.?\d*)\\?\(Dr\\?$');
  final amountCrRx = RegExp(r'^([\d,]+\.?\d*)\\?\(Cr\\?$');
  final transIdRx = RegExp(r'^[A-Z]?\d{5,}$', caseSensitive: false);

  while (i < lines.length) {
    final dateMatch = dateRx.firstMatch(lines[i]);
    if (dateMatch != null) {
      final day = int.tryParse(dateMatch.group(1)!);
      final month = int.tryParse(dateMatch.group(2)!);
      final year = int.tryParse(dateMatch.group(3)!);

      if (year != null && year >= 2000 && year <= 2030) {
        int refIdx = i + 1;
        while (refIdx < lines.length && !transIdRx.hasMatch(lines[refIdx])) {
          refIdx++;
          if (refIdx >= i + 4) break;
        }

        if (refIdx < lines.length) {
          int remarksIdx = refIdx + 1;
          if (remarksIdx < lines.length) {
            final remarks = lines[remarksIdx];
            int amountIdx = remarksIdx + 1;

            while (amountIdx < lines.length) {
              final drMatch = amountDrRx.firstMatch(lines[amountIdx]);
              final crMatch = amountCrRx.firstMatch(lines[amountIdx]);

              if (drMatch != null || crMatch != null) {
                final amountMatch = drMatch ?? crMatch;
                final amountStr = amountMatch!.group(1)!.replaceAll(',', '');
                final amount = double.tryParse(amountStr);
                if (amount != null && amount > 0) {
                  final isCredit = crMatch != null;
                  print('FOUND: $lines[i] $remarks $amountStr(${crMatch != null ? "Cr" : "Dr"})');
                }
                i = amountIdx;
                break;
              }
              amountIdx++;
              if (amountIdx >= remarksIdx + 5) break;
            }
          }
        }
      }
    }
    i++;
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
