# Regenerating the i18n files

The files in this directory are used to generate `stock_strings.dart`, which
is used by the stocks application to look up localized message strings. The
stocks app uses the [Dart `intl` package](https://github.com/dart-lang/intl).

Rebuilding everything requires two steps.

1. Create or update the English and Spanish localizations,
`stocks_en_US.arb`, `stocks_en.arb`, and `stocks_es.arb`. See the
[ARB specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
for more info.

2. With `examples/stocks` as the current directory, generate a
`messages_<locale>.dart` for each `stocks_<locale>.arb` file,
`messages_all.dart`, and `stock_strings.dart` with the following command:

```dart
dart ${FLUTTER_PATH}/dev/tools/localization/bin/gen_l10n.dart --arb-dir=lib/i18n \
    --template-arb-file=stocks_en.arb --output-localization-file=stock_strings.dart \
    --output-class=StockStrings --header-file=header.txt
```

The `StockStrings` class creates a delegate that performs message lookups
based on the locale of the device. In this case, the stocks app supports
`en`, `en_US`, and `es`. Thus, the `StockStringsEn` and `StockStringsEs`
classes extends `StockStrings`. `StockStringsEnUs` extends
`StockStringsEn`. This allows `StockStringsEnUs` to fall back on messages
in `StockStringsEn`.