import 'dart:io';
import 'package:expense_ai_agent/services/ai_categorization_service.dart';

void main() {
  final svc = AICategorizationService();

  print('Testing categorization accuracy...');

  // Test some known categorizations
  print('Capgemini categorization: ${svc.categorize("capgemini")}');
  print('Google India categorization: ${svc.categorize("google india")}');
  print('Swiggy categorization: ${svc.categorize("swiggy")}');
  print(
    'Nema Ram Chaudhary categorization: ${svc.categorize("nema ram chaudhary")}',
  );

  // Test with context
  print(
    'Capgemini with salary context: ${svc.categorizeWithDescription("capgemini", "salary credit", true, 85000)}',
  );
  print(
    'Swiggy with UPI context: ${svc.categorizeWithDescription("swiggy", "UPI payment", false, 500)}',
  );
}
