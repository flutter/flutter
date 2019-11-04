# Regenerating the i18n files

The files in this directory are based on ../lib/i18n/stock_strings.dart,
which defines all of the localizable strings used by the stocks
app. The stocks app uses
the [Dart `intl` package](https://github.com/dart-lang/intl).

Rebuilding everything requires two steps.

1. Create the English and Spanish localizations, `stocks_en_EN.arb` and
`stocks_es_ES.arb`. See the [ARB specifications](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
for more info.

2. With the `examples/stocks` as the current directory, generate a
`messages_<locale>.dart` for each `stocks_<locale>.arb` file,
`messages_all.dart`, and `stock_strings.dart` with the following command:

```dart
dart ${FLUTTER_PATH}/dev/tools/localization/gen_l10n.dart --arb-dir=lib/i18n
  --template-arb-file=stocks_en_EN.arb --output-localization-file=stock_strings
  --output-class=StockStrings
```

The `StockStrings` class uses the generated `initializeMessages()`function
(`messages_all.dart`) to load the localized messages and `Intl.message()`
to look them up.
