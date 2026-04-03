class ChatService {
  List<String> generateInsights({
    required double totalSpend,
    required double upiPercent,
    required int repeatCount,
    required int smallSpendCount,
  }) {
    List<String> messages = [];

    // Total spend insight
    if (totalSpend > 5000) {
      messages.add(
        "You've spent quite a bit this period. Might be worth reviewing your major expenses.",
      );
    } else {
      messages.add("Your overall spending looks relatively controlled.");
    }

    // UPI usage insight
    if (upiPercent > 70) {
      messages.add(
        "Most of your spending is through UPI. Small frequent payments might be slipping unnoticed.",
      );
    }

    // Repeats
    if (repeatCount > 2) {
      messages.add(
        "You have repeated transactions that look like subscriptions or habits.",
      );
    }

    // Small spends
    if (smallSpendCount > 10) {
      messages.add(
        "Many small expenses are adding up. These are easy to miss but impactful.",
      );
    }

    return messages;
  }
}
