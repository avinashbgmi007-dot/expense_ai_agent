import 'dart:convert';
import 'dart:io';
import '../models/transaction.dart';

class PDFParserService {
  Future<List<TransactionModel>> parsePDF(File file) async {
    final contents = await file.readAsBytes();
    final text = _extractAllText(contents);

    if (text.isEmpty) {
      throw Exception(
        'Could not extract text from PDF. Ensure it\'s a text-based statement.',
      );
    }

    final transactions = _parseAllTransactions(text);

    if (transactions.isEmpty) {
      throw Exception(
        'No transactions found in PDF. Check if it\'s a valid bank statement.',
      );
    }

    return _deduplicateTransactions(transactions);
  }

  // =========================================================================
  // TEXT EXTRACTION
  // =========================================================================

  String _extractAllText(List<int> bytes) {
    final allStrings = <String>[];

    // Search for stream/endstream in raw bytes (not decoded string)
    int pos = _indexOfBytes(bytes, 'stream', 0);
    while (pos != -1) {
      // Check for newline after 'stream'
      int streamContentStart = -1;
      if (pos + 8 <= bytes.length &&
          bytes[pos + 6] == 13 &&
          bytes[pos + 7] == 10) {
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
        try {
          dec = zlib.decode(streamBytes);
        } catch (_) {
          try {
            dec = ZLibCodec(raw: true).decode(streamBytes);
          } catch (_) {}
        }
        if (dec != null) {
          final text = utf8.decode(dec, allowMalformed: true);
          for (final m in RegExp(r'\(([^\)]*)\)').allMatches(text)) {
            var s = m.group(1)!;
            if (s.isEmpty) continue;
            int printable =
                s.codeUnits.where((c) => (c >= 32 && c <= 126)).length;
            if (printable > s.length * 0.7) {
              allStrings.add(s);
            }
          }
        }
      } catch (_) {}

      pos = _indexOfBytes(bytes, 'stream', endIdx + 9);
    }

    if (allStrings.isEmpty) {
      return _extractRawReadableText(bytes);
    }

    return allStrings.join('\n');
  }

  /// Find ASCII text pattern in a byte list, starting from `start`.
  int _indexOfBytes(List<int> bytes, String pattern, int start) {
    final units = pattern.codeUnits;
    if (start + units.length > bytes.length) return -1;
    for (int i = start; i <= bytes.length - units.length; i++) {
      bool match = true;
      for (int j = 0; j < units.length; j++) {
        if (bytes[i + j] != units[j]) {
          match = false;
          break;
        }
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

  // =========================================================================
  // FORMAT DETECTION
  // =========================================================================

  List<TransactionModel> _parseAllTransactions(String text) {
    // Try Union Bank / Axis format first (DD-MM-YYYY with UPIAR/UPIAB patterns)
    if (_isUnionBankFormat(text)) {
      final txns = _parseUnionBankStatement(text);
      if (txns.isNotEmpty) return txns;
    }

    // Then try HDFC style
    if (_isHDFCFormat(text)) {
      final txns = _parseHDFCStatement(text);
      if (txns.isNotEmpty) return txns;
    }

    // Generic fallback
    return _parseGenericStatement(text.split('\n'));
  }

  bool _isUnionBankFormat(String text) {
    // Union Bank has DD-MM-YYYY dates with UPIAR/UPIAB patterns
    int ddmmmyyyyCount = RegExp(r'\d{2}-\d{2}-\d{4}').allMatches(text).length;
    int upiAbArCount = RegExp(r'UPI[AB]R/').allMatches(text).length;

    return ddmmmyyyyCount >= 5 && upiAbArCount >= 3;
  }

  bool _isHDFCFormat(String text) {
    final indicators = [
      'Statement of account',
      'Narration',
      'Withdrawal',
      'Deposit',
      'Closing',
      'Balance',
      'UPI-',
      'NEFT',
      'CR-',
    ];
    int hits = 0;
    for (final ind in indicators) {
      if (text.contains(ind)) hits++;
    }
    return hits >= 3;
  }

  // =========================================================================
  // UNION BANK / AXIS STYLE PARSER
  //
  // Format: Each transaction is 4 strings:
  //   [Date: DD-MM-YYYY]
  //   [TransID: S\d+/AA\d+/ST\d+]
  //   [Remarks: UPIAR/UPIAB/description]
  //   [Amount: XXXXX.X\(Dr\ or Cr\]
  //   [Balance: XXXXX.XX\(Cr\] -- balance line, skip
  //
  // Between pages, there's page header text that needs to be skipped.
  // =========================================================================

  List<TransactionModel> _parseUnionBankStatement(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final transactions = <TransactionModel>[];
    int i = 0;

    final dateRx = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
    final amountDrRx = RegExp(r'^([\d,]+\.?\d*)\\?\(Dr\\?$');
    final amountCrRx = RegExp(r'^([\d,]+\.?\d*)\\?\(Cr\\?$');

    while (i < lines.length) {
      final dateMatch = dateRx.firstMatch(lines[i]);

      if (dateMatch != null) {
        final day = int.tryParse(dateMatch.group(1)!);
        final month = int.tryParse(dateMatch.group(2)!);
        final year = int.tryParse(dateMatch.group(3)!);

        // Validate date
        if (day != null &&
            month != null &&
            year != null &&
            year >= 2000 &&
            year <= 2030 &&
            month >= 1 &&
            month <= 12 &&
            day >= 1 &&
            day <= 31) {
          // Try to find the transaction block after this date
          // Format: Date -> TransID -> Remarks -> Amount\(Dr/Cr\) -> Balance\(Cr\)
          // TransId can be: S90880893 (S + digits), AA289254 (AA + digits), ST6001150 (ST + digits)
          final transIdRx = RegExp(r'^[A-Z]+(\d{5,}|T\d{5,})$', caseSensitive: false);
          int refIdx = i + 1;

          // Skip to find transaction ID
          while (refIdx < lines.length &&
              !transIdRx.hasMatch(lines[refIdx])) {
            refIdx++;
            if (refIdx >= i + 4) break; // too far, not a valid transaction
          }

          if (refIdx < lines.length) {
            // Find the remarks line (after transId)
            int remarksIdx = refIdx + 1;
            if (remarksIdx < lines.length) {
              final remarks = lines[remarksIdx];

              // Find amount line - look for lines with \(Dr\) or \(Cr\)
              int amountIdx = remarksIdx + 1;
              while (amountIdx < lines.length) {
                final drMatch = amountDrRx.firstMatch(lines[amountIdx]);
                final crMatch = amountCrRx.firstMatch(lines[amountIdx]);

                if (drMatch != null || crMatch != null) {
                  final amountStr =
                      (drMatch ?? crMatch)!.group(1)!.replaceAll(',', '');
                  final amount = double.tryParse(amountStr);

                  if (amount != null && amount > 0) {
                    final isCredit = crMatch != null;

                    // Extract merchant from remarks
                    String merchant = _extractUnionBankMerchant(remarks);
                    final method = _detectPaymentMethodFromUnionBank(remarks);
                    final description = remarks;

                    // Fallback merchant for known-but-unnamed patterns
                    if (merchant == 'Unknown') {
                      final lr = remarks.toLowerCase();
                      if (remarks.contains('CASH')) {
                        merchant = 'Cash';
                      } else if (remarks.startsWith('BY ') || remarks.startsWith('FRM ')) {
                        merchant = 'Bank Transfer';
                      } else if (remarks.contains('Int.Pd:') || lr.contains('interest')) {
                        merchant = 'Interest';
                      } else if (lr.contains('sms')) {
                        merchant = 'SMS Charges';
                      } else if (lr.contains('pmsby')) {
                        merchant = 'PMSBY Insurance';
                      } else if (lr.contains('accidental ins')) {
                        merchant = 'Accidental Ins';
                      } else if (lr.contains('debit card')) {
                        merchant = 'Debit Card Charges';
                      }
                    }

                    if (merchant.isNotEmpty && merchant != 'Unknown') {
                      final txnDate = DateTime(year, month, day);
                      // Include transaction ID in the unique key to prevent
                      // false deduplication of same-date/amount/merchant txns.
                      final txnId = lines[refIdx];
                      transactions.add(TransactionModel(
                        id: '${txnDate.millisecondsSinceEpoch}_${merchant.hashCode}_$amount${txnId.hashCode}',
                        timestamp: txnDate.millisecondsSinceEpoch,
                        amount: amount,
                        currency: 'INR',
                        description: description,
                        credit: isCredit,
                        merchant: merchant,
                        paymentMethod: method,
                        uploadId: 'pdf_union',
                        createdAt: DateTime.now(),
                      ));
                    }
                  }

                  // Skip past this transaction (amount + balance lines)
                  // Typically: Date, TransID, Remarks, Amount(Dr/Cr), Balance(Cr)
                  // That's ~5 lines per transaction, but remarks can be multi-line
                  i = amountIdx;
                  break;
                }

                amountIdx++;
                // Don't look beyond a reasonable distance
                if (amountIdx >= remarksIdx + 3) break;
              }
            }
          }
        }
      }

      i++;
    }

    return transactions;
  }

  String _extractUnionBankMerchant(String remarks) {
    final lower = remarks.toLowerCase();

    // Check for known merchants
    final known = {
      'googlepa': 'google pay',
      'goog-payment': 'google pay',
      'hmwssb': 'hmwssb bill',
      'select c': 'select cars',
      'selectcars': 'select cars',
      'avinasha': 'avinash',
      'avinashavi': 'avinash transfer',
      'godesravanthi': 'g sravan',
      'pasannapragada': 'pasanna pragada',
      'g sravan': 'g sravan',
      'malyadrich': 'chavidi balaiah',
      'chaividi': 'chavidi balaiah',
      'sms charges': 'sms charges',
      'debit card charges': 'debit card charges',
      'pmsby': 'pmsby insurance',
      'accidental ins': 'accidental insurance',
      'int.pd': 'interest paid',
      'by cash': 'cash deposit',
      'by ': 'bank transfer',
      'by': 'bank transfer',
      'fr': 'bank transfer',
      'frm': 'bank transfer',
    };
    for (final entry in known.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    // Skip generic/nonsensical UPI merchant names early
    final skipNames = {'dummy na', 'dummy', 'na', 'test', 'gpay'};

    // Extract from UPIAR/DR pattern: UPIAR/.../DR/NAME/BANK/id
    final drMatch = RegExp(
      r'/DR/([^/]+)/([^/]+)/',
      caseSensitive: false,
    ).firstMatch(remarks);
    if (drMatch != null) {
      var name = drMatch.group(1)!.trim().toLowerCase();
      if (name != 'annaprag' && !skipNames.contains(name)) {
        return name;
      }
    }

    // Extract from UPIAB/CR pattern: UPIAB/.../CR/NAME/BANK/id
    final crMatch = RegExp(
      r'/CR/([^/]+)/([^/]+)/',
      caseSensitive: false,
    ).firstMatch(remarks);
    if (crMatch != null) {
      var name = crMatch.group(1)!.trim().toLowerCase();
      if (name != 'annaprag' && !skipNames.contains(name)) {
        return name;
      }
    }

    // Skip generic/nonsensical UPI merchant names
    if (lower.contains('dummy na') || lower.contains('dummy')) {
      // Use the bank from the transaction instead
      final bankMatch = RegExp(r'/(punb|sbin|anndb|hdfc|barb|axis|utib|andb)/',
          caseSensitive: false).firstMatch(remarks);
      if (bankMatch != null) {
        return '${bankMatch.group(1)?.toUpperCase()} transfer';
      }
      return 'Unknown';
    }

    // Bank internal transfer (from/to own account)
    final bankMatch = RegExp(r'/(punb|sbin|anndb|hdfc|barb|axis|utib|andb)/',
        caseSensitive: false).firstMatch(remarks);
    if (bankMatch != null) {
      return '${bankMatch.group(1)?.toUpperCase()} transfer';
    }

    return 'Unknown';
  }

  String _detectPaymentMethodFromUnionBank(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('upi')) return 'UPI';
    if (lower.contains('neft')) return 'NEFT';
    if (lower.contains('cash')) return 'Cash';
    if (lower.contains('rtgs')) return 'RTGS';
    return 'UPI';
  }

  // =========================================================================
  // HDFC STYLE PARSER
  //
  // Format: DD/MM/YY dates, separate withdrawal/deposit amounts
  // =========================================================================

  List<TransactionModel> _parseHDFCStatement(String text) {
    final dateRx = RegExp(r'^(\d{2})/(\d{2})/(\d{2})$');
    final amountRx = RegExp(r'^([\d,]+\.\d{2})$');

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Step 1: Find all value date indices
    final valueDateIndices = <int>{};
    for (int i = 0; i < lines.length; i++) {
      if (!dateRx.hasMatch(lines[i])) continue;
      int k = i + 1;
      while (k < lines.length && _isHeaderOrFooterLine(lines[k])) {
        k++;
      }
      if (k < lines.length && amountRx.hasMatch(lines[k])) {
        valueDateIndices.add(i);
      }
    }

    // Step 2: Parse transactions
    final transactions = <TransactionModel>[];
    int i = 0;

    while (i < lines.length) {
      final dm = dateRx.firstMatch(lines[i]);

      if (dm != null) {
        final day = int.parse(dm.group(1)!);
        final month = int.parse(dm.group(2)!);
        final yearRaw = int.parse(dm.group(3)!);
        final year = yearRaw < 50 ? 2000 + yearRaw : 1900 + yearRaw;

        if (year >= 2019 &&
            year <= 2030 &&
            month >= 1 &&
            month <= 12 &&
            day >= 1 &&
            day <= 31) {
          // If this is a value date (part of another txn), skip
          if (valueDateIndices.contains(i)) {
            i++;
            continue;
          }

          // This is a potential transaction start date
          final txnDate = DateTime(year, month, day);

          // Collect narration until we hit a value date
          final narrBuffer = StringBuffer();
          int valueDateIdx = -1;
          int amountIdx = -1;

          for (int j = i + 1; j < lines.length; j++) {
            if (valueDateIndices.contains(j)) {
              valueDateIdx = j;
              // Find the amount after this value date
              int k = j + 1;
              while (k < lines.length && _isHeaderOrFooterLine(lines[k])) {
                k++;
              }
              if (k < lines.length && amountRx.hasMatch(lines[k])) {
                amountIdx = k;
              }
              break;
            }

            if (!_isHeaderOrFooterLine(lines[j])) {
              narrBuffer.write(' ${lines[j]}');
            }
          }

          if (amountIdx >= 0 && narrBuffer.toString().trim().isNotEmpty) {
            final v = double.tryParse(
              lines[amountIdx].replaceAll(',', ''),
            );
            if (v != null && v > 0) {
              final narration = narrBuffer.toString().trim();
              final merchant = _extractMerchant(narration);
              final isCredit = _isCredit(narration);
              final method = _detectPaymentMethod(narration);

              if (merchant != 'Unknown') {
                transactions.add(TransactionModel(
                  id: '${txnDate.millisecondsSinceEpoch}_${merchant.hashCode}_$v',
                  timestamp: txnDate.millisecondsSinceEpoch,
                  amount: v,
                  currency: 'INR',
                  description: narration,
                  credit: isCredit,
                  merchant: merchant,
                  paymentMethod: method,
                  uploadId: 'pdf_hdfc',
                  createdAt: DateTime.now(),
                ));
              }
            }
            // Advance i past the value date
            i = valueDateIdx;
          }
        }
      }

      i++;
    }

    return transactions;
  }

  bool _isHeaderOrFooterLine(String line) {
    final skipPatterns = [
      r'^Page\s*No',
      r'^HDFC\s*BANK',
      r'^Nomination',
      r'^Account\s*Branch',
      r'^Address\s*:',
      r'^City\s*:',
      r'^State\s*:',
      r'^Phone\s*no',
      r'^OD\s*Limit',
      r'^Currency\s*:',
      r'^Cust\s*ID',
      r'^Email\s*:',
      r'^Branch\s*Code',
      r'^RTGS/NEFT',
      r'^A/C\s*Open\s*Date',
      r'^SAVINGS',
      r'^Generated\s*(On|By)',
      r'^STATEMENT\s*SUMMARY',
      r'^Opening\s*Balance',
      r'^This is a computer',
      r'^Contents\s*of',
      r'^State\s*account',
      r'^HDFC\s*Bank\s*GST',
      r'^Registered\s*(Office|Statement)',
      r'^From\s*:',
      r'^To\s*:',
      r'^Date\s+Narration',
      r'^Statement\s*of',
      r'.*GSTN\s*:',
      r'.*MICR\s*:',
      r'^IFSC\s*:',
      r'^Account\s*Type\s*:',
      r'^Account\s*Status\s*:',
      r'^HOUSE\s*NO',
      r'^PLOT\s*NO',
      r'^COLONY',
      r'^GURRAM',
      r'^OPP\s*RICE',
      r'^HYDERABAD\s+\d',
      r'^TELANGANA',
      r'^JOINT\s*HOLDERS',
      r'^ANNAPRAGADA',
      r'^AVINASH',
      r'^DILSUKHNAGAR',
      r'^SALEEM\s*NAGAR',
      r'^MALAKPET',
      r'^MR\s*$',
      r'^SRI\s*RAM',
      r'^NAGAR\s*$',
      r'INDIA\s*$',
      r'^Closing\s*(balance|Bal)',
      r':\s*$',
      r'^\(\d+\)$',
      r'^\d{2}-\d{2}-\d{4}', // Skip Union Bank dates in HDFC parser
      r'^\d{2}-\d{2}-\d{2}',
    ];
    for (final p in skipPatterns) {
      if (RegExp(p, caseSensitive: false).hasMatch(line)) return true;
    }
    return false;
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  bool _isCredit(String narration) {
    final lower = narration.toLowerCase();
    return lower.contains(' cr ') ||
        lower.contains('cr-') ||
        lower.contains('salary') ||
        lower.contains('cashback') ||
        lower.contains('refund') ||
        lower.contains('interest');
  }

  String _detectPaymentMethod(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('neft')) return 'NEFT';
    if (lower.contains('upi')) return 'UPI';
    if (lower.contains('rtgs')) return 'RTGS';
    if (lower.contains('cash')) return 'Cash';
    if (lower.contains('bhim')) return 'BHIM';
    return 'UPI';
  }

  // =========================================================================
  // CATEGORIZATION ENGINE (HDFC)
  // =========================================================================

  String _extractMerchant(String text) {
    final lower = text.toLowerCase();

    final known = {
      'capgemini': 'capgemini',
      'google india': 'google india',
      'google india digital': 'google india',
      'google pay': 'google pay',
      'nema ram': 'nema ram chaudhary',
      'korra': 'korra sunitha',
      'anipindi': 'anipindi durgaprasad',
      'seethala': 'seethala manasa',
      'siri vallabh': 'siri vallabh hospital',
      'siri vallabh hospita': 'siri vallabh hospital',
      'siri vallabh pharmac': 'siri vallabh pharmacy',
      'siri vallabh pharma': 'siri vallabh pharmacy',
      'siri vallabh hosp': 'siri vallabh hospital',
      'madani': 'madani hemanth kumar',
      'manchala': 'manchala sravanthi',
      'kandala': 'kandala mane esha bal',
      'mamu': 'mamu s food',
      'raksh': 'raksh medical',
      'rakesh medical': 'rakesh medical',
      'bathula': 'bathula naveen kumar',
      'kondapalli': 'kondapalli deepthika',
      'pasanna': 'pasanna pragada',
      'karamtothu': 'karamtothu ravi',
      'nagati': 'nagati bhiksha pathi',
      'oruganti': 'oruganti yadaiah',
      'shiva shankar': 'shiva shankar vegetables',
      'jakkula': 'jakkula bhaskar',
      'aleti': 'aleti shekar reddy',
      'sher khan': 'sher khan mohammed',
      'om desserts': 'om desserts',
      'manne': 'manne sai vardhan',
      'samruddhi': 'samruddhi amrutulya',
      'bachalakuri': 'bachalakuri purnaiah',
      'purnaiah': 'bachalakuri purnaiah',
      'cityflo': 'cityflo',
      'dumpa': 'dumpa rambabu',
      'sampradaya': 'sampradaya tiffins',
      'sri vekateshwara': 'sri vekateshwara kirana',
      'sri vekateshwara kir': 'sri vekateshwara kirana',
      'murugan': 'murugan kanniyapp',
      'ambey': 'ambey kirana general',
      'payzapp': 'payzapp wallet',
      'payzapp wallet': 'payzapp wallet',
      'uidai': 'uidai',
      'ch v k': 'ch v k subramanyam',
      'kolluru': 'kolluru sai ram',
      'subramanyam': 'ch v k subramanyam',
      'bharatpe': 'bharatpe',
      'paytm': 'paytm',
      'npci': 'npci bhim',
      'bhim': 'npci bhim',
      'google': 'google india',
      'santosh': 'santosh',
      'sani': 'sani',
      'ramavath': 'ramavath mounika',
      'jafruddin': 'jafruddin khan',
      'alpati': 'alpati gopal',
      'gaddam': 'gaddam sai baba',
      'emmarasu': 'emmarasu kumar',
      'pz hdfc cc': 'hdfc credit card bill',
      'city court': 'city court',
    };
    for (final entry in known.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    // UPI name extraction
    final upiMatch = RegExp(
      r'UPI[-\s]([A-Za-z][A-Za-z\s\.]{2,40})',
      caseSensitive: false,
    ).firstMatch(text);
    if (upiMatch != null) {
      var name = upiMatch.group(1)!.trim();
      final cleanParts = <String>[];
      for (final token in name.split(RegExp(r'\s+'))) {
        final tl = token.toLowerCase();
        if (tl.contains('@') ||
            ['gpay', 'okbiz', 'okicici', 'okaxis', 'oksbi', 'okhdfcbank',
              'bharatpe', 'paytm', 'pzhdfc'].any((p) => tl.contains(p))) {
          break;
        }
        cleanParts.add(token);
      }
      if (cleanParts.isNotEmpty) {
        return cleanParts.join(' ').trim().toLowerCase();
      }
    }

    // NEFT pattern
    final neftMatch = RegExp(
      r'NEFT[^A-Za-z]*-([A-Za-z]{2,30})',
      caseSensitive: false,
    ).firstMatch(text);
    if (neftMatch != null) {
      final name = neftMatch.group(1)!.trim();
      if (name.length >= 3) return name.trim().toLowerCase();
    }

    // Fallback
    final tokens = text.split(RegExp(r'[-/.,@|_\s]+'));
    for (final token in tokens) {
      final clean = token.replaceAll(RegExp(r'[^\w]'), '').toLowerCase();
      if (clean.length >= 3 &&
          clean.length <= 30 &&
          !RegExp(r'\d').hasMatch(token) &&
          ![
            'upi', 'neft', 'rtgs', 'bhim', 'gpay', 'cashback', 'hdfcbank',
            'hdfc', 'npci', 'norem', 'remarks', 'potential', 'residents',
            'salary', 'account', 'statement', 'from', 'city', 'state',
            'pay', 'to', 'cr', 'feb', 'scblh', 'services', 'india',
            'avinash', 'technology', 'mab', 'uboi', 'yesbank',
          ].contains(clean)) {
        return clean[0].toUpperCase() + clean.substring(1);
      }
    }

    return 'Unknown';
  }

  // =========================================================================
  // GENERIC FALLBACK PARSER
  // =========================================================================

  List<TransactionModel> _parseGenericStatement(List<String> lines) {
    final transactions = <TransactionModel>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final txn = _tryParseLine(line.trim());
      if (txn != null) transactions.add(txn);
    }
    return transactions;
  }

  TransactionModel? _tryParseLine(String line) {
    final genericMatch = RegExp(
      r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\s+([\d,]+\.?\d{2})\s+(.+)$',
    ).firstMatch(line.trim());

    if (genericMatch != null) {
      final year = int.parse(genericMatch.group(1)!);
      final month = int.parse(genericMatch.group(2)!);
      final day = int.parse(genericMatch.group(3)!);
      final amount = double.tryParse(
        genericMatch.group(4)!.replaceAll(',', ''),
      );
      if (amount == null || amount <= 0) return null;

      DateTime date;
      try {
        date = DateTime(year, month, day);
      } catch (_) {
        return null;
      }

      String merchant = genericMatch.group(5)!.trim();
      // Clean up PDF artifacts like "(Name) Tj"
      merchant = merchant
          .replaceAll(RegExp(r'\s*Tj\s*$'), '')
          .replaceAll(RegExp(r'\s*\(\s*'), '')
          .replaceAll(RegExp(r'\s*\)\s*'), '')
          .trim();
      if (merchant.isEmpty) return null;

      return TransactionModel(
        id:
            '${date.millisecondsSinceEpoch}_${merchant.hashCode}_$amount',
        timestamp: date.millisecondsSinceEpoch,
        amount: amount,
        currency: 'INR',
        description: merchant,
        credit: false,
        merchant: merchant,
        paymentMethod: 'Unknown',
        uploadId: 'pdf_generic',
        createdAt: DateTime.now(),
      );
    }

    return null;
  }

  // =========================================================================
  // DEDUPLICATION
  // =========================================================================

  List<TransactionModel> _deduplicateTransactions(
    List<TransactionModel> txns,
  ) {
    final seen = <String>{};
    return txns.where((t) {
      final key =
          '${t.timestamp}-${t.amount.toStringAsFixed(2)}-${t.merchant}';
      return seen.add(key);
    }).toList();
  }
}
