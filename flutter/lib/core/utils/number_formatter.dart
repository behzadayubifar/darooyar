/// Utility class for formatting numbers in the application
class NumberFormatter {
  /// Formats a number with thousands separators
  /// Example: 1000000 -> 1,000,000
  static String formatWithCommas(dynamic number) {
    if (number == null) return '0';

    // Convert to string if it's not already
    String numStr = number.toString();

    // Handle decimal numbers
    if (numStr.contains('.')) {
      List<String> parts = numStr.split('.');
      String integerPart = parts[0];
      String decimalPart = parts[1];

      // Format the integer part with commas
      String formattedInteger = _addCommasToInteger(integerPart);

      return '$formattedInteger.${decimalPart}';
    } else {
      // Format integer
      return _addCommasToInteger(numStr);
    }
  }

  /// Helper method to add commas to integer part
  static String _addCommasToInteger(String integerStr) {
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return integerStr.replaceAllMapped(reg, (Match match) => '${match[1]},');
  }

  /// Formats a price with thousands separators and adds تومان suffix
  static String formatPrice(dynamic price) {
    return '${formatWithCommas(price)} تومان';
  }

  /// Formats a price in thousands of Tomans
  /// Example: 45 -> 45 هزار تومن
  static String formatPriceInThousands(dynamic price) {
    // Convert to double if it's not already
    double priceValue = double.tryParse(price.toString()) ?? 0;

    // Format the price without decimal places
    String formattedPrice = formatWithCommas(priceValue.toStringAsFixed(0));

    return '$formattedPrice هزار تومن';
  }
}
