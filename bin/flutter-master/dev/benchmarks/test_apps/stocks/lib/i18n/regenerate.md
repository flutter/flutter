# Regenerating the i18n files

The arb files in this directory are used to generate `stock_strings.dart`,
which contains the `StockStrings` class. This localizations class is
used by the stocks application to look up localized message strings.
The stocks app uses the [Dart `intl` package](https://github.com/dart-lang/intl).

To update the English and Spanish localizations, modify the
`stocks_en_US.arb`, `stocks_en.arb`, or `stocks_es.arb` files. See the
[ARB specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
for more info.

To modify the project's configuration of the localizations tool,
change the `l10n.yaml` file.

The `StockStrings` class creates a delegate that performs message lookups
based on the locale of the device. In this case, the stocks app supports
`en`, `en_US`, and `es` locales. Thus, the `StockStringsEn` and
`StockStringsEs` classes extends `StockStrings`. `StockStringsEnUs` extends
`StockStringsEn`. This allows `StockStringsEnUs` to fall back on messages
in `StockStringsEn`.
