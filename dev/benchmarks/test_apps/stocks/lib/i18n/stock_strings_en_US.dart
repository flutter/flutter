// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'stock_strings_en.dart';

// ignore_for_file: unnecessary_brace_in_string_interps

/// The translations for English, as used in the United States (`en_US`).
class StockStringsEnUs extends StockStringsEn {
  StockStringsEnUs([String locale = 'en_US']) : super(locale);

  @override
  String get title => 'Stocks';

  @override
  String get market => 'MARKET';

  @override
  String get portfolio => 'PORTFOLIO';
}