import 'dart:io';
import 'dart:convert';
import 'package:expense_ai_agent/services/pdf_parser_service.dart';

void main() async {
  final file = File('Union_Bank.pdf');
  final bytes = await file.readAsBytes();
  
  print('PDF size: ${bytes.length} bytes');
  
  // Try the same zlib extraction the PDF parser does
  int pos = _indexOfBytes(bytes, 'stream', 0);
  int streamCount = 0;
  while (pos != -1) {
    streamCount++;
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
      try { dec = zlib.decode(streamBytes); } catch (_) {
        try { dec = ZLibCodec(raw: true).decode(streamBytes); } catch (_) {}
      }
      if (dec != null) {
        final text = utf8.decode(dec, allowMalformed: true);
        // Count PDF text objects - parentheses with content
        final matches = RegExp(r'\(([^\)]{3,})\)').allMatches(text).toList();
        if (matches.isNotEmpty) {
          print('Stream #$streamCount: ${matches.length} text objects');
          // Show first 3 matches
          for (int m = 0; m < matches.length && m < 10; m++) {
            print('  MATCH: "${matches[m].group(1)}"');
          }
        }
      } else {
        print('Stream #$streamCount: decompression failed (size: ${endIdx - streamContentStart})');
      }
    } catch (e) {
      print('Stream #$streamCount: error: $e');
    }
    
    pos = _indexOfBytes(bytes, 'stream', endIdx + 9);
  }
  print('Total streams: $streamCount');
  
  // Now try raw byte extraction
  print('\n=== RAW BYTE EXTRACTION (first 2000 chars) ===');
  final rawLines = _extractRawReadableText(bytes).split('\n');
  for (int i = 0; i < rawLines.length && i < 50; i++) {
    final line = rawLines[i].trim();
    if (line.isNotEmpty) {
      print('$i: "$line"');
    }
  }
  
  // Check for Union Bank indicators
  print('\n=== CHECKING UNION BANK FORMAT INDICATORS ===');
  final allText = _extractRawReadableText(bytes);
  int ddmmmyyyyCount = RegExp(r'\d{2}-\d{2}-\d{4}').allMatches(allText).length;
  int upiAbArCount = RegExp(r'UPI[AB]R/').allMatches(allText).length;
  print('DD-MM-YYYY dates: $ddmmmyyyyCount');
  print('UPIAR/UPIAB refs: $upiAbArCount');
  print('Is Union format? ${ddmmmyyyyCount >= 5 && upiAbArCount >= 3}');
  
  // Look for BY CASH and ACCIDENTAL in the raw text
  print('\n=== LINES WITH "BY" OR "ACCIDENTAL" ===');
  for (final line in allText.split('\n')) {
    final lower = line.trim().toLowerCase();
    if ((lower.startsWith('by ') || lower.startsWith('by c') || lower == 'by') || 
        lower.contains('accidental')) {
      print('-> "$line"');
    }
  }
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
