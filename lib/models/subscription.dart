// lib/models/subscription.dart

/// A class to represent a subscription plan in the app.
class SubscriptionModel {
  /// The unique identifier for this subscription.
  final String id;

  /// The name of the subscription plan.
  final String name;

  /// The description of the subscription plan.
  final String description;

  /// The price of the subscription plan in the user's currency.
  final double price;

  /// The duration of the subscription plan, in days.
  final int duration;

  /// Whether this subscription is currently active or not.
  bool active = false;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
  });

  /// Creates a new subscription model from JSON data.
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as double,
      duration: json['duration'] as int,
    );
  }

  /// Returns a list of subscription models from JSON data.
  static List<SubscriptionModel> fromJsonList(List<dynamic> json) {
    return json.map((e) => SubscriptionModel.fromJson(e)).toList();
  }
}
