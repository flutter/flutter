# Regenerating the i18n files

The files in this directory are used to generate `stock_strings[_locale].dart`
, which is used by the stocks application to look up localized message
strings. The stocks app uses the [Dart `intl` package](https://github.com/dart-lang/intl).

To update the English and Spanish localizations, modify the
`stocks_en_US.arb`, `stocks_en.arb`, or `stocks_es.arb` files. See the
[ARB specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
for more info.

To modify the project's configuration of the localizations tool,
see `l10n.yaml` for the list of options used.

The `StockStrings` class creates a delegate that performs message lookups
based on the locale of the device. In this case, the stocks app supports
`en`, `en_US`, and `es`. Thus, the `StockStringsEn` and `StockStringsEs`
classes extends `StockStrings`. `StockStringsEnUs` extends
`StockStringsEn`. This allows `StockStringsEnUs` to fall back on messages
in `StockStringsEn`.
