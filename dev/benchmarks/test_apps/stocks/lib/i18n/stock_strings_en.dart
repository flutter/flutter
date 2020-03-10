// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'stock_strings.dart';

// ignore_for_file: unnecessary_brace_in_string_interps

/// The translations for English (`en`).
class StockStringsEn extends StockStrings {
  StockStringsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Stocks';

  @override
  String get market => 'MARKET';

  @override
  String get portfolio => 'PORTFOLIO';
}