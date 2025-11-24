import 'dart:convert';

class MarketTrend {
  final String cropName;
  final double currentPrice;
  final double forecastedPrice; // Price expected in X days
  final int forecastDays; // e.g., 4 days
  final double priceChange; // absolute difference
  final double percentChange;
  final String recommendation; // "Hold", "Sell Now"
  final DateTime lastUpdated;

  MarketTrend({
    required this.cropName,
    required this.currentPrice,
    required this.forecastedPrice,
    required this.forecastDays,
    required this.priceChange,
    required this.percentChange,
    required this.recommendation,
    required this.lastUpdated,
  });

  factory MarketTrend.fromJson(Map<String, dynamic> json) {
    return MarketTrend(
      cropName: json['crop_name'],
      currentPrice: (json['current_price'] as num).toDouble(),
      forecastedPrice: (json['forecasted_price'] as num).toDouble(),
      forecastDays: json['forecast_days'] as int,
      priceChange: (json['price_change'] as num).toDouble(),
      percentChange: (json['percent_change'] as num).toDouble(),
      recommendation: json['recommendation'],
      lastUpdated: DateTime.parse(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop_name': cropName,
      'current_price': currentPrice,
      'forecasted_price': forecastedPrice,
      'forecast_days': forecastDays,
      'price_change': priceChange,
      'percent_change': percentChange,
      'recommendation': recommendation,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
