class SafeParser {
  static String parseString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    try {
      if (value is String) return value.trim();
      return value.toString().trim();
    } catch (e) {
      return defaultValue;
    }
  }

  static int parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    try {
      if (value is int) return value;
      if (value is double) return value.round();

      String stringValue = value.toString().trim();

      // Deteksi UUID
      if (RegExp(
        r'^[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+',
      ).hasMatch(stringValue)) {
        return defaultValue;
      }

      return int.tryParse(stringValue) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  static double parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    try {
      if (value is double) return value.isFinite ? value : defaultValue;
      if (value is int) return value.toDouble();

      String stringValue = value.toString().trim();

      // Deteksi UUID
      if (RegExp(
        r'^[0-9a-fA-F]+-[0-9a-fA-F]+-[0-9a-fA-F]+',
      ).hasMatch(stringValue)) {
        return defaultValue;
      }

      return double.tryParse(stringValue) ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
}
