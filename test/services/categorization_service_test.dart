import 'package:test/test.dart';

import 'package:expense_ai_agent/services/categorization_service.dart';

void main() {
  group('CategorizationService', () {
    late CategorizationService service;

    setUp(() {
      service = CategorizationService(['Swiggy', 'Uber', 'Netflix', 'Amazon']);
    });

    test('swiggy', () {
      expect(service.categorize('Swiggy'), 'food');
    });

    test('uber', () {
      expect(service.categorize('Uber'), 'transport');
    });

    test('netflix', () {
      expect(service.categorize('Netflix'), 'subscriptions');
    });

    test('unknown', () {
      expect(service.categorize('Unknown'), 'miscellaneous');
    });

    test('edge cases', () {
      expect(service.categorize('swiggy'), 'food'); // lowercase
      expect(service.categorize('swi ggy'), 'food'); // spaces
      expect(service.categorize('SwYgY'), 'food'); // typos
    });
  });
}
