import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('Union_Bank.pdf');
  final bytes = await file.readAsBytes();

  // Extract ALL (text)Tj strings from ALL streams (union format)
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

          // Extract ALL (text)Tj strings
          for (final m in RegExp(r'\(([^)]*)\)Tj').allMatches(text)) {
            var s = m.group(1)!;
            if (s.isEmpty) continue;
            int printable = s.codeUnits.where((c) => (c >= 32 && c <= 126) || c == 10 || c == 13 || c == 0x5C).length;
            if (printable > s.length * 0.5) {
              allStrings.add(s);
            }
          }

          // Also extract raw readable text from this stream (fallback)
          final readable = StringBuffer();
          for (int i = 0; i < dec.length; i++) {
            final c = dec[i];
            if ((c >= 32 && c <= 126) || c == 10 || c == 13) {
              readable.write(String.fromCharCode(c));
            } else if (c == 0x5C) {
              readable.write('\\');
            }
          }

          // Look for "Amount" in readable text to detect UNION format
          if (readable.toString().contains('Date') &&
              readable.toString().contains('Remarks')) {
            // This is a transaction text stream
            // Parse amounts that follow "Amount" keyword
            final raw = readable.toString();

            // Count transactions: find date patterns followed by amount patterns
            final dateMatches = RegExp(r'\d{2}-\d{2}-\d{4}').allMatches(raw);
            final amountMatches = RegExp(r'([\d,]+\.?\d*)\\?\\?\((Dr|Cr)\\?\\?\)').allMatches(raw);

            for (final m in amountMatches) {
              print('UNION amount: "${m.group(1)}" ${m.group(2)}');
            }
          }
      }
    } catch (_) {}

    pos = _indexOfBytes(bytes, 'stream', endIdx + 9);
  }

  // Now process allStrings to count transactions
  print('\n\n=== ALL EXTRACTED STRINGS (${allStrings.length}) ===');
  bool inTransactions = false;
  int txnCount = 0;

  // Parse like union bank: date + ref + remarks + amount(Dr/Cr) + balance(Cr)
  // Pattern: DD-MM-YYYY, then S\d+ or AA\d+ date, then narration, then amount, then balance
  for (int i = 0; i < allStrings.length; i++) {
    final s = allStrings[i];

    // Look for DD-MM-YYYY pattern (union format)
    if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(s)) {
      txnCount++;
      print('TXN #$txnCount: Date=$s');

      // Next strings: Transaction ID, Remarks, Amount(, balance
      if (i + 1 < allStrings.length) print('  Ref: ${allStrings[i + 1]}');
      if (i + 2 < allStrings.length) print('  Rem: ${allStrings[i + 2]}');
      if (i + 3 < allStrings.length) print('  Amt: ${allStrings[i + 3]}');
      if (i + 4 < allStrings.length) print('  Bal: ${allStrings[i + 4]}');
    }
  }

  print('\nTotal transactions (from date count): $txnCount');
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