import 'package:flutter_test/flutter_test.dart';
import 'package:expense_ai_agent/services/ai_categorization_service.dart';

void main() {
  final svc = AICategorizationService();

  group('Pass 1: Exact merchant rules', () {
    test('Person names → transfers', () {
      expect(svc.categorize('pasanna pragada'), 'transfers');
      expect(svc.categorize('g sravan'), 'transfers');
      expect(svc.categorize('nema ram chaudhary'), 'transfers');
    });

    test('Short names exact match only', () {
      expect(svc.categorize('cash'), 'transfers');
      expect(svc.categorize('avinash'), 'transfers');
      // cashew should NOT match "cash" → context default for amount=0 → bills
      expect(svc.categorize('cashew nuts'), 'bills');
    });

    test('Food merchants', () {
      expect(svc.categorize('swiggy'), 'food');
      expect(svc.categorize('zomato'), 'food');
      expect(svc.categorize('dominos'), 'food');
      expect(svc.categorize('mamu s food'), 'food');
      expect(svc.categorize('shiva shankar vegetables'), 'food');
      expect(svc.categorize('zepto'), 'food');
      expect(svc.categorize('blinkit'), 'food');
      expect(svc.categorize('bigbasket'), 'food');
    });

    test('Income merchants', () {
      expect(svc.categorize('capgemini'), 'income');
      expect(svc.categorize('google india'), 'income');
    });

    test('Healthcare', () {
      expect(svc.categorize('raksh medical'), 'healthcare');
      expect(svc.categorize('apollo pharmacy'), 'healthcare');
      expect(svc.categorize('siri vallabh hospital'), 'healthcare');
    });

    test('Finance/Investments', () {
      expect(svc.categorize('zerodha'), 'finance');
      expect(svc.categorize('groww'), 'finance');
      expect(svc.categorize('lic'), 'finance');
      expect(svc.categorize('cred'), 'finance');
    });

    test('Transport', () {
      expect(svc.categorize('uber'), 'transport');
      expect(svc.categorize('ola'), 'transport');
      expect(svc.categorize('irctc'), 'transport');
      expect(svc.categorize('redbus'), 'transport');
    });

    test('Utility bills', () {
      expect(svc.categorize('hmwssb'), 'utilities');
      expect(svc.categorize('tata power'), 'utilities');
    });

    test('Mobile', () {
      expect(svc.categorize('jio'), 'mobile');
      expect(svc.categorize('airtel'), 'mobile');
    });

    test('Subscriptions', () {
      expect(svc.categorize('netflix'), 'subscriptions');
      expect(svc.categorize('youtube premium'), 'subscriptions');
    });
  });

  group('Pass 2: Description patterns', () {
    test('Cash withdrawal → transfers', () {
      expect(
        svc.categorizeWithDescription('ATM', 'cash withdrawal', false, 5000),
        'transfers',
      );
    });

    test('SMS charges → bills', () {
      expect(
        svc.categorizeWithDescription('SBI', 'sms charges', false, 5),
        'bills',
      );
    });

    test('Interest → income', () {
      expect(
        svc.categorizeWithDescription('HDFC', 'interest credited', true, 50),
        'income',
      );
    });

    test('NACH/Auto-pay → subscriptions', () {
      expect(
        svc.categorizeWithDescription('Netflix', 'nach mandate payment', false, 649),
        'subscriptions',
      );
    });

    test('Salary credit → income', () {
      expect(
        svc.categorizeWithDescription('Capgemini', 'credit salary', true, 50000),
        'income',
      );
    });
  });

  group('Pass 3: Keyword matching', () {
    test('Food keywords', () {
      expect(svc.categorizeWithDescription('XYZ Store', 'restaurant bill', false, 500), 'food');
      expect(svc.categorizeWithDescription('XYZ Store', 'bakery purchase', false, 200), 'food');
      expect(svc.categorizeWithDescription('XYZ', 'kirana store', false, 300), 'food');
    });

    test('Transport keywords', () {
      expect(svc.categorizeWithDescription('XYZ', 'uber ride', false, 200), 'transport');
      // "petrol" is in description patterns, so "petrol pump" → transport
      expect(svc.categorizeWithDescription('Indian Oil', 'petrol pump', false, 1500), 'transport');
    });

    test('Shopping keywords', () {
      expect(svc.categorizeWithDescription('XYZ', 'flipkart order', false, 2000), 'shopping');
      expect(svc.categorizeWithDescription('XYZ', 'myntra purchase', false, 800), 'shopping');
    });
  });

  group('Pass 4: Context defaults', () {
    test('Large credit → income', () {
      expect(svc.categorizeWithDescription('Unknown', '', true, 50000), 'income');
    });

    test('Small debit (<50) → bills', () {
      expect(svc.categorizeWithDescription('Unknown', '', false, 30), 'bills');
    });

    test('Medium debit (200-2000) → food default', () {
      expect(svc.categorizeWithDescription('Unknown', '', false, 500), 'food');
    });
  });

  group('Edge cases - false positive prevention', () {
    test('Cash should not match cashew', () {
      expect(svc.categorizeWithDescription('cashew store', '', false, 500) != 'transfers', true);
    });

    test('avinash should not match avinash restaurant (if not exact)', () {
      expect(svc.categorizeWithDescription('avinash restaurant', '', false, 1000) != 'transfers', true);
    });
  });

  group('Payment gateway deferral', () {
    test('Paytm Jio recharge → mobile', () {
      expect(
        svc.categorizeWithDescription('Paytm', 'jio mobile recharge', false, 299),
        'mobile',
      );
    });

    test('PhonePe Netflix autopay → subscriptions', () {
      expect(
        svc.categorizeWithDescription('PhonePe', 'netflix autopay', false, 649),
        'subscriptions',
      );
    });

    test('Cred standalone → finance', () {
      expect(svc.categorize('cred'), 'finance');
    });
  });

  group('Real-world bank transactions', () {
    test('UPI to person → transfers', () {
      expect(
        svc.categorizeWithDescription('pasanna pragada', 'UPI-PAYMENT', false, 2000),
        'transfers',
      );
    });

    test('Swiggy via UPI → food', () {
      expect(
        svc.categorizeWithDescription('Swiggy', 'UPI-P2M payment', false, 350),
        'food',
      );
    });

    test('Zomato food → food', () {
      expect(
        svc.categorizeWithDescription('zomato', 'upi payment', false, 450),
        'food',
      );
    });

    test('LIC insurance → finance', () {
      expect(
        svc.categorizeWithDescription('LIC of India', 'insurance premium', false, 3000),
        'finance',
      );
    });

    test('Netflix → subscriptions', () {
      expect(
        svc.categorizeWithDescription('Netflix India', 'autopay charge', false, 649),
        'subscriptions',
      );
    });

    test('IRCTC train ticket → transport', () {
      expect(
        svc.categorizeWithDescription('IRCTC', 'train booking', false, 800),
        'transport',
      );
    });

    test('Jio recharge → mobile', () {
      expect(
        svc.categorizeWithDescription('Jio', 'prepaid recharge', false, 299),
        'mobile',
      );
    });

    test('Capgemini salary credit → income', () {
      expect(
        svc.categorizeWithDescription('CAPGEMINI TECH SERVICES', 'salary credit', true, 85000),
        'income',
      );
    });

    test('Zepto grocery → food', () {
      expect(
        svc.categorizeWithDescription('zepto', 'grocery purchase via upi', false, 780),
        'food',
      );
    });

    test('PMSBY health insurance → healthcare', () {
      expect(
        svc.categorizeWithDescription('SBI', 'pmsby insurance', false, 436),
        'healthcare',
      );
    });
  });

  group('confidence scores', () {
    test('Exact merchant rule → 0.99', () {
      expect(
        svc.getConfidence('food', 'swiggy', 'UPI payment', false) >= 0.99,
        true,
      );
    });

    test('Substring merchant → 0.97', () {
      expect(
        svc.getConfidence('food', 'Swiggy Instamart', 'UPI', false) >= 0.97,
        true,
      );
    });
  });
}
