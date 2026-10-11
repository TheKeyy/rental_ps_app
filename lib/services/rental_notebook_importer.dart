class RentalNotebookImporter {
  static String? parseStartTime(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final timePattern = RegExp(r'(\d{1,2})\s*[:.]\s*(\d{2})');
    final match = timePattern.firstMatch(text) ??
        RegExp(r'(\d{1,2})\s+(\d{2})').firstMatch(text);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  static int? parseDurationMinutes(String value) {
    final text = value.trim().toLowerCase().replaceAll(',', '.');
    if (text.isEmpty) return null;

    final hoursAndMinutes = RegExp(
      r'(\d+)\s*(?:jam|j|hours?|hrs?|h)\s*(?:(\d+)\s*(?:menit|min|mins?|m))?',
    ).firstMatch(text);
    if (hoursAndMinutes != null) {
      final hours = int.tryParse(hoursAndMinutes.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(hoursAndMinutes.group(2) ?? '') ?? 0;
      if (minutes >= 60) return null;
      final total = hours * 60 + minutes;
      return total > 0 ? total : null;
    }

    // Many handwritten ledgers abbreviate 1 hour 20 minutes as "1.20 m".
    final compactHour = RegExp(r'^(\d+)\s*[.:]\s*(\d{1,2})\s*(?:m|min|menit)?$')
        .firstMatch(text);
    if (compactHour != null) {
      final hours = int.tryParse(compactHour.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(compactHour.group(2) ?? '') ?? 0;
      if (minutes >= 60) return null;
      final total = hours * 60 + minutes;
      return total > 0 ? total : null;
    }

    final minuteValue = RegExp(r'(\d+)\s*(?:menit|min|mins?|m)\b?').firstMatch(text);
    if (minuteValue != null) {
      final minutes = int.tryParse(minuteValue.group(1) ?? '');
      return minutes != null && minutes > 0 ? minutes : null;
    }
    return null;
  }

  /// Interprets ledger currency such as "Rp 10.000" or "2.000 L".
  /// Dots and commas are treated as thousands separators, not decimals.
  static int? parseAmount(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  /// Stable key for one row on one photo; it is stored alongside the imported
  /// rental so opening/importing the same photo again does not duplicate it.
  static String fingerprint(Map<String, String> row) {
    const fields = ['no', 'nama', 'ps', 'waktu', 'sewa', 'saldo'];
    return fields
        .map((key) => (row[key] ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
        .join('|');
  }
}
