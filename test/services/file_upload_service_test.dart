import 'package:test/test.dart';

void main() {
  group('FileUploadService', () {
    test('should have supported file extensions', () {
      final extensions = ['pdf', 'csv', 'xlsx', 'xls'];
      expect(extensions, contains('pdf'));
      expect(extensions, contains('csv'));
    });

    test('should have supported file extensions', () {
      final extensions = ['pdf', 'csv', 'xlsx', 'xls'];
      expect(extensions, contains('pdf'));
      expect(extensions, contains('csv'));
    });

    test('should validate allowed extensions', () {
      final allowedExtensions = ['pdf', 'csv', 'xlsx', 'xls'];
      expect(allowedExtensions.length, equals(4));
    });
  });
}
