import 'package:intl/intl.dart';

final _amount = NumberFormat.decimalPattern('fr_FR');

/// 800000 -> "800 000 FCFA" (spaces that never break the line)
String formatFcfa(num amount) =>
    '${_amount.format(amount.round()).replaceAll(RegExp(r'\s'), '\u00A0')}\u00A0FCFA';
