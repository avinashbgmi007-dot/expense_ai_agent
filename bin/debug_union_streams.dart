import 'dart:io';
import 'dart:convert';

void main() async {
  final bytes = await File('Union_Bank.pdf').readAsBytes();
  
  // Count streams
  int pos = _indexOfBytes(bytes, 'stream', 0);
  int streamNum = 0;
  while (pos != -1) {
    streamNum++;
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
      try { dec = ZLibCodec(raw: true).decode(streamBytes); } catch (_) {}
      if (dec != null) {
        final text = utf8.decode(dec, allowMalformed: true);
        final matches = RegExp(r'\(([^)]{3,})\)').allMatches(text).toList();
        final readable = matches.where((m) {
          final s = m.group(1)!;
          int printable = s.codeUnits.where((c) => (c >= 32 && c <= 126)).length;
          return printable > s.length * 0.7;
        }).map((m) => m.group(1)!).toList();
        
        print('Stream #$streamNum (${endIdx - streamContentStart} bytes): ${readable.length} readable strings');
        
        // Look for date patterns, BY CASH, etc.
        for (final s in readable) {
          if (s.contains('BY') || s.contains('CASH') || s.contains('FRM') ||
              s.contains('ACCIDENTAL') || s.contains('SMS') || s.contains('Int.Pd')) {
            print('  >> "$s"');
          }
        }
        if (streamNum == 1) {
          print('  First 20:');
          for (int i = 0; i < readable.length && i < 20; i++) {
            print('    "$readable[i]"');
          }
        }
      } else {
        // Check if it's not compressed - maybe raw FlateDecode
        print('Stream #$streamNum: decompression failed, trying raw');
        final text = utf8.decode(streamBytes, allowMalformed: true);
        final matches = RegExp(r'\(([^)]{3,})\)').allMatches(text).toList();
        final readable = matches.where((m) {
          final s = m.group(1)!;
          int printable = s.codeUnits.where((c) => (c >= 32 && c <= 126)).length;
          return printable > s.length * 0.7;
        }).map((m) => m.group(1)!).toList();
        print('  Raw readable: ${readable.length} strings');
        for (int i = 0; i < readable.length && i < 20; i++) {
          print('    "$readable[i]"');
        }
      }
    } catch (e) {
      print('Stream #$streamNum: error: $e');
    }
    
    pos = _indexOfBytes(bytes, 'stream', endIdx + 9);
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
