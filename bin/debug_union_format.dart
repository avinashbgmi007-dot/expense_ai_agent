import 'dart:io';
import 'dart:convert';
import '../lib/services/pdf_parser_service.dart';

void main() async {
  final file = File('Union_Bank.pdf');
  
  // Read raw bytes and try format detection
  final bytes = await file.readAsBytes();
  final text = _extractAllText(bytes);
  
  // Print format detection results
  final ddMmYyyy = RegExp(r'\d{2}-\d{2}-\d{4}').allMatches(text).length;
  final upiArAb = RegExp(r'UPI[AB]R/').allMatches(text).length;
  final isUnionBank = ddMmYyyy >= 5 && upiArAb >= 3;
  
  print('Union Bank format detection:');
  print('  DD-MM-YYYY dates: $ddMmYyyy');
  print('  UPI-AR/AB refs: $upiArAb');
  print('  Detected as Union Bank: $isUnionBank');
  
  // Check for HDFC indicators
  final indicators = [
    'Statement of account', 'Narration', 'Withdrawal', 'Deposit',
    'Closing', 'Balance', 'UPI-', 'NEFT', 'CR-',
  ];
  int hits = 0;
  for (final ind in indicators) {
    if (text.contains(ind)) hits++;
  }
  print('  HDFC indicator hits: $hits (needs >= 3)');
  
  print('\nFirst 20 lines of extracted text:');
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  for (int i = 0; i < lines.length && i < 20; i++) {
    print('  $i: "${lines[i]}"');
  }
  
  print('\nTotal extracted lines: ${lines.length}');
  
  // Now check actual transaction extraction
  print('\n--- Actual transaction extraction ---');
  final service = PDFParserService();
  try {
    final txns = await service.parsePDF(file);
    print('Successfully parsed ${txns.length} transactions');
    
    // Group by type
    var credits = txns.where((t) => t.isCredit).length;
    var debits = txns.length - credits;
    print('Credits: $credits, Debits: $debits');
    
    // Show merchant distribution
    var merchants = <String, int>{};
    for (final t in txns) {
      merchants[t.merchant] = (merchants[t.merchant] ?? 0) + 1;
    }
    print('Unique merchants: ${merchants.length}');
    
    print('\nSample transactions (first 10):');
    for (int i = 0; i < txns.length && i < 10; i++) {
      final t = txns[i];
      print('  ${i+1}. ${t.description} | Rs.${t.amount} | ${t.isCredit ? "CR" : "DR"} | ${t.merchant}');
    }
    
    // Count specific patterns
    var byCash = txns.where((t) => t.description == 'BY CASH').length;
    var byTransfer = txns.where((t) => t.description == 'BY 142110027040124').length;
    var frmTransfer = txns.where((t) => t.description == 'FRM 142110027040124').length;
    var accidental = txns.where((t) => t.description == 'ACCIDENTAL INS REN PREM').length;
    print('\nSpecific checks:');
    print('  BY CASH entries: $byCash (expected 2)');
    print('  BY 142110027040124 entries: $byTransfer (expected 1)');
    print('  FRM 142110027040124 entries: $frmTransfer (expected 1)');
    print('  ACCIDENTAL INS entries: $accidental (expected 1)');
    print('  Total non-UPI entries: ${byCash + byTransfer + frmTransfer} (expected 4)');
    print('  Total expected: 53 + 4 = 57');
    print('  Actual total: ${txns.length}');
    
  } catch (e) {
    print('ERROR: $e');
  }
}

String _extractAllText(List<int> bytes) {
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
      final streamBytes = bytes.sublist(streamContentStart, endIdx);
      List<int>? dec;
      try { dec = zlib.decode(streamBytes); } catch (_) {
        try { dec = ZLibCodec(raw: true).decode(streamBytes); } catch (_) {}
      }
      if (dec != null) {
        final text = utf8.decode(dec, allowMalformed: true);
        for (final m in RegExp(r'\(([^\)]*)\)').allMatches(text)) {
          var s = m.group(1)!;
          if (s.isEmpty) continue;
          int printable = s.codeUnits.where((c) => (c >= 32 && c <= 126)).length;
          if (printable > s.length * 0.7) {
            allStrings.add(s);
          }
        }
      }
    } catch (_) {}
    pos = _indexOfBytes(bytes, 'stream', endIdx + 9);
  }
  if (allStrings.isEmpty) {
    return _extractRaw(bytes);
  }
  return allStrings.join('\n');
}

String _extractRaw(List<int> bytes) {
  final buffer = StringBuffer();
  for (final b in bytes) {
    if ((b >= 32 && b <= 126) || b == 10 || b == 13) {
      buffer.write(String.fromCharCode(b));
    } else {
      buffer.write(' ');
    }
  }
  var text = buffer.toString();
  text = text.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return text.trim();
}

int _indexOfBytes(List<int> bytes, String pattern, int start) {
  final units = pattern.codeUnits;
  if (start + units.length > bytes.length) return -1;
  for (int i = start; i <= bytes.length - units.length; i++) {
    bool match = true;
    for (int j = 0; j < units.length; j++) {
      if (bytes[i + j] != units[j]) { match = false; break; }
    }
    if (match) return i;
  }
  return -1;
}
