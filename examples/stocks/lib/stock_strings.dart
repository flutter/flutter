part of stocks;

// Wrappers for strings that are shown in the UI.  The strings can be
// translated for different locales using the Dart intl package.
//
// Locale-specific values for the strings live in the i18n/*.arb files.
//
// To generate the stock_messages_*.dart files from the ARB files, run:
//   pub run intl:generate_from_arb --output-dir=lib/i18n --generated-file-prefix=stock_ --no-use-deferred-loading lib/stock_strings.dart lib/i18n/stocks_*.arb

class StockStrings extends LocaleQueryData {
  static StockStrings of(BuildContext context) {
    return LocaleQuery.of(context);
  }

  static final StockStrings instance = new StockStrings();

  String title() => Intl.message(
    'Stocks',
    name: 'title',
    desc: 'Title for the Stocks application'
  );

  String market() => Intl.message(
    'MARKET',
    name: 'market',
    desc: 'Label for the Market tab'
  );

  String portfolio() => Intl.message(
    'PORTFOLIO',
    name: 'portfolio',
    desc: 'Label for the Portfolio tab'
  );
}
