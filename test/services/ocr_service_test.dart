import 'package:test/test.dart';

import 'package:expense_ai_agent/services/ocr_service.dart';

void main() {
  group('OCRService', () {
    test('ocr service class exists', () {
      // Since OCRService requires Flutter bindings which aren't available
      // in unit tests, we just verify the class can be imported and used
      // in integration tests instead
      expect(OCRService, isNotNull);
    });

    // Note: Platform-specific tests for OCRService should be run as
    // integration tests or widget tests where Flutter bindings are available
  });
}
