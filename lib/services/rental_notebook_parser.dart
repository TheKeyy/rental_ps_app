class RentalNotebookParser {
  /// Best-effort parsing of OCR text for the notebook columns:
  /// No | Nama | PS | Waktu | Sewa | Saldo.
  ///
  /// Only lines that look like six columns are converted. Ambiguous lines are
  /// deliberately skipped and can be entered manually in the review screen.
  static List<Map<String, String>> parseRows(String text) {
    final rows = <Map<String, String>>[];

    for (final rawLine in text.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final lower = line.toLowerCase();
      if (lower.contains('nama') &&
          lower.contains('ps') &&
          lower.contains('waktu') &&
          lower.contains('saldo')) {
        continue;
      }

      List<String> cells = [];
      if (line.contains('|')) {
        cells = line.split('|').map((cell) => cell.trim()).toList();
      } else if (line.contains('\t')) {
        cells = line.split('\t').map((cell) => cell.trim()).toList();
      } else if (RegExp(r'\s{2,}').hasMatch(line)) {
        cells = line.split(RegExp(r'\s{2,}')).map((cell) => cell.trim()).toList();
      } else {
        final match = RegExp(
          r'^\s*(\d+)\s+(.+?)\s+(?:PS\s*)?(\d+)\s+(\d{1,2}[:.]\d{2}(?:\s*[-–]\s*\d{1,2}[:.]\d{2})?)\s+(.+?)\s+((?:Rp\.?\s*)?[\d.,]+)\s*$',
          caseSensitive: false,
        ).firstMatch(line);
        if (match != null) {
          cells = [
            match.group(1) ?? '',
            match.group(2) ?? '',
            match.group(3) ?? '',
            match.group(4) ?? '',
            match.group(5) ?? '',
            match.group(6) ?? '',
          ];
        }
      }

      if (cells.length < 6) continue;
      if (cells.first.toLowerCase() == 'no' || cells[1].toLowerCase() == 'nama') {
        continue;
      }

      rows.add({
        'no': cells[0],
        'nama': cells[1],
        'ps': cells[2].replaceFirst(RegExp(r'^PS\s*', caseSensitive: false), ''),
        'waktu': cells[3],
        'sewa': cells[4],
        'saldo': cells[5],
      });
    }

    return rows;
  }
}
