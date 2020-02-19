# Regenerating the i18n files

The files in this directory are used to generate `stock_strings.dart`, which
is used by the stocks application to look up localized message strings. The
stocks app uses the [Dart `intl` package](https://github.com/dart-lang/intl).

Rebuilding everything requires two steps.

1. Create or update the English and Spanish localizations, `stocks_en_US.arb`
and `stocks_es_ES.arb`. See the [ARB specification](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
for more info.

2. With `examples/stocks` as the current directory, generate a
`messages_<locale>.dart` for each `stocks_<locale>.arb` file,
`messages_all.dart`, and `stock_strings.dart` with the following command:

```dart
dart ${FLUTTER_PATH}/dev/tools/localization/bin/gen_l10n.dart --arb-dir=lib/i18n \
    --template-arb-file=stocks_en_US.arb --output-localization-file=stock_strings.dart \
    --output-class=StockStrings
```

The `StockStrings` class uses the generated `initializeMessages()`function
(`messages_all.dart`) to load the localized messages and `Intl.message()`
to look them up. The generated class's API documentation explains how to add
the new localizations delegate and supported locales to the Flutter application.
