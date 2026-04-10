import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('Union_Bank.pdf');
  final bytes = await file.readAsBytes();

  // Extract ONLY (text)Tj strings from ALL streams
  int pos = 0;
  int streamNum = 0;
  final allTextStrings = <String>[];

  while (true) {
    pos = _indexOfBytes(bytes, 'stream', pos);
    if (pos == -1) break;
    streamNum++;

    int streamContentStart = -1;
    if (pos + 8 <= bytes.length && bytes[pos + 6] == 13 && bytes[pos + 7] == 10) {
      streamContentStart = pos + 8;
    } else if (pos + 7 <= bytes.length && bytes[pos + 6] == 10) {
      streamContentStart = pos + 7;
    } else {
      pos++;
      continue;
    }

    int endIdx = _indexOfBytes(bytes, 'endstream', streamContentStart);
    if (endIdx == -1) break;

    final compressedBytes = bytes.sublist(streamContentStart, endIdx);
    List<int>? dec;
    try { dec = zlib.decode(compressedBytes); } catch (_) {}
    if (dec == null) {
      try { dec = ZLibCodec(raw: true).decode(compressedBytes); } catch (_) {}
    }

    if (dec != null) {
      final text = utf8.decode(dec, allowMalformed: true);

        // Extract ALL (text)Tj patterns
        for (final m in RegExp(r'\(([^)]*)\)Tj').allMatches(text)) {
          var s = m.group(1)!;
          // Check if printable
          int printable = s.runes.where((c) => (c >= 32 && c <= 126) || c == 10 || c == 13).length;
          int total = s.runes.length;
          if (printable > total * 0.3) {
            // Clean up non-printable unicode
            final clean = s.replaceAllMapped(
              RegExp(r'[^\x20-\x7E\x0A\x0D]'),
              (_) => ' ',
            );
            allTextStrings.add('[$streamNum] $clean');
          }
        }
    }

    pos = endIdx + 9;
  }

  print('TOTAL TEXT STRINGS: ${allTextStrings.length}');
  for (int i = 0; i < allTextStrings.length; i++) {
    print(allTextStrings[i]);
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
