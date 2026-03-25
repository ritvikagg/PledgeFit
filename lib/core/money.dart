/// Decimal-safe money handling using integer cents.
///
/// This avoids floating-point rounding issues when computing penalties
/// (e.g. 20% of the daily deposit).
class Money {
  final int cents;

  const Money(this.cents);

  static const Money zero = Money(0);

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);

  bool get isZero => cents == 0;

  /// Returns a string like `$30.00`.
  String format() {
    final abs = cents.abs();
    final dollars = abs ~/ 100;
    final centsPart = abs % 100;
    final sign = cents < 0 ? '-' : '';
    return '$sign\$$dollars.${centsPart.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {'cents': cents};

  static Money fromJson(Map<String, dynamic> json) => Money(json['cents'] as int);
}

