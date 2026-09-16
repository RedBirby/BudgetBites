/// Scales the leading amount in a recipe ingredient for a new serving count.
///
/// This intentionally leaves descriptive quantities such as "to taste" and
/// "as needed" unchanged. Package sizes after a multiplication sign are also
/// left intact: "2 × 15 oz cans" becomes "4 × 15 oz cans" when doubled.
String scaleIngredientQuantity(
  String quantity, {
  required int originalServings,
  required int targetServings,
}) {
  if (originalServings <= 0 || targetServings <= 0) return quantity;
  if (originalServings == targetServings) return quantity;

  final match = RegExp(
    r'^\s*((?:\d+(?:\.\d+)?(?:\s+\d+\/\d+)?|\d+\/\d+|\d+[¼½¾⅐⅑⅒⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]|[¼½¾⅐⅑⅒⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]))(\s*.*)$',
  ).firstMatch(quantity);
  if (match == null) return quantity;

  final amount = _parseAmount(match.group(1)!);
  if (amount == null) return quantity;

  final scaled = amount * targetServings / originalServings;
  final formatted = _formatAmount(scaled);
  return '$formatted${match.group(2)!}';
}

double? _parseAmount(String token) {
  final normalized = token.trim();
  final unicodeFraction = <String, double>{
    '¼': 0.25,
    '½': 0.5,
    '¾': 0.75,
    '⅐': 1 / 7,
    '⅑': 1 / 9,
    '⅒': 0.1,
    '⅓': 1 / 3,
    '⅔': 2 / 3,
    '⅕': 0.2,
    '⅖': 0.4,
    '⅗': 0.6,
    '⅘': 0.8,
    '⅙': 1 / 6,
    '⅚': 5 / 6,
    '⅛': 0.125,
    '⅜': 0.375,
    '⅝': 0.625,
    '⅞': 0.875,
  };

  final attachedFraction = RegExp(
    r'^(\d+)([¼½¾⅐⅑⅒⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞])$',
  ).firstMatch(normalized);
  if (attachedFraction != null) {
    return double.parse(attachedFraction.group(1)!) +
        unicodeFraction[attachedFraction.group(2)!]!;
  }

  final mixedFraction = RegExp(
    r'^(\d+)\s+(\d+)\/(\d+)$',
  ).firstMatch(normalized);
  if (mixedFraction != null) {
    final denominator = int.parse(mixedFraction.group(3)!);
    if (denominator == 0) return null;
    return double.parse(mixedFraction.group(1)!) +
        int.parse(mixedFraction.group(2)!) / denominator;
  }

  final slashFraction = RegExp(r'^(\d+)\/(\d+)$').firstMatch(normalized);
  if (slashFraction != null) {
    final denominator = int.parse(slashFraction.group(2)!);
    if (denominator == 0) return null;
    return int.parse(slashFraction.group(1)!) / denominator;
  }

  final unicodeOnly = unicodeFraction[normalized];
  if (unicodeOnly != null) return unicodeOnly;
  return double.tryParse(normalized);
}

String _formatAmount(double amount) {
  final fractions = <double, String>{
    0.125: '⅛',
    1 / 6: '⅙',
    0.2: '⅕',
    0.25: '¼',
    1 / 3: '⅓',
    0.375: '⅜',
    0.4: '⅖',
    0.5: '½',
    0.6: '⅗',
    0.625: '⅝',
    2 / 3: '⅔',
    0.75: '¾',
    0.8: '⅘',
    5 / 6: '⅚',
    0.875: '⅞',
  };

  final roundedInteger = amount.roundToDouble();
  if ((amount - roundedInteger).abs() < 0.001) {
    return roundedInteger.toInt().toString();
  }

  final whole = amount.floor();
  final fraction = amount - whole;
  var nearest = fractions.entries.first;
  var distance = (fraction - nearest.key).abs();
  for (final candidate in fractions.entries.skip(1)) {
    final candidateDistance = (fraction - candidate.key).abs();
    if (candidateDistance < distance) {
      nearest = candidate;
      distance = candidateDistance;
    }
  }
  if (distance < 0.025) {
    return whole == 0 ? nearest.value : '$whole${nearest.value}';
  }

  final decimal = amount.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return decimal.endsWith('.')
      ? decimal.substring(0, decimal.length - 1)
      : decimal;
}
