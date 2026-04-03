import 'package:test/test.dart';
import 'package:expense_ai_agent/services/csv_parser_service.dart';

void main() {
  group('CSVParserService', () {
    late CSVParserService service;

    setUp(() {
      service = CSVParserService();
    });

    test('should parse CSV fields with quotes correctly', () {
      final line = '"2024-01-15","500","Amazon","Online Purchase"';
      final fields = service.parseCSVFields(line);

      expect(fields.length, equals(4));
      expect(fields[0], contains('2024'));
      expect(fields[1], contains('500'));
      expect(fields[2], contains('Amazon'));
    });

    test('should parse CSV fields without quotes', () {
      final line = '2024-01-15,500,Amazon,Online Purchase';
      final fields = service.parseCSVFields(line);

      expect(fields.length, equals(4));
      expect(fields[0].trim(), equals('2024-01-15'));
      expect(fields[1].trim(), equals('500'));
    });

    test('should detect CSV header correctly', () {
      final linesWithHeader = [
        'Date,Amount,Merchant,Description',
        '2024-01-15,500,Amazon,Purchase',
      ];
      final hasHeader = service.hasHeader(linesWithHeader);
      expect(hasHeader, isTrue);
    });

    test('should detect CSV without header', () {
      final linesNoHeader = [
        '2024-01-15,500,Amazon,Purchase',
        '2024-01-16,300,Swiggy,Food',
      ];
      final hasHeader = service.hasHeader(linesNoHeader);
      expect(hasHeader, isFalse);
    });

    test('should parse date format YYYY-MM-DD', () {
      final date = service.parseDate('2024-01-15');
      expect(date, isNotNull);
      expect(date!.year, equals(2024));
      expect(date.month, equals(1));
      expect(date.day, equals(15));
    });

    test('should parse date format DD-MM-YYYY', () {
      final date = service.parseDate('15-01-2024');
      expect(date, isNotNull);
      expect(date!.year, equals(2024));
      expect(date.month, equals(1));
      expect(date.day, equals(15));
    });

    test('should parse date format DD/MM/YYYY', () {
      final date = service.parseDate('15/01/2024');
      expect(date, isNotNull);
      expect(date!.year, equals(2024));
    });

    test('should return null for invalid date', () {
      final date = service.parseDate('invalid-date');
      expect(date, isNull);
    });

    test('should parse amount with currency symbols', () {
      final amount1 = service.parseAmount('₹500');
      expect(amount1, equals(500));

      final amount2 = service.parseAmount('\$100');
      expect(amount2, equals(100));

      final amount3 = service.parseAmount('€50');
      expect(amount3, equals(50));
    });

    test('should parse amount with comma separator', () {
      final amount = service.parseAmount('1,000.50');
      expect(amount, equals(1000.50));
    });

    test('should return null for invalid amount', () {
      final amount = service.parseAmount('no-number');
      expect(amount, isNull);
    });

    test('should handle empty values', () {
      expect(service.parseAmount(''), isNull);
      expect(service.parseDate(''), isNull);
    });
  });
}
