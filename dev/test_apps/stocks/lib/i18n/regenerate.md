## Regenerating the i18n files

The files in this directory are based on ../lib/stock_strings.dart
which defines all of the localizable strings used by the stocks
app. The stocks app uses
the [Dart `intl` package](https://github.com/dart-lang/intl).

Rebuilding everything requires two steps.

With the `examples/stocks` as the current directory, generate
`intl_messages.arb` from `lib/stock_strings.dart`:
```
flutter pub pub run intl_translation:extract_to_arb --output-dir=lib/i18n lib/stock_strings.dart
```
The `intl_messages.arb` file is a JSON format map with one entry for
each `Intl.message()` function defined in `stock_strings.dart`. This
file was used to create the English and Spanish localizations,
`stocks_en.arb` and `stocks_es.arb`. The `intl_messages.arb` wasn't
checked into the repository, since it only serves as a template for
the other `.arb` files.


With the `examples/stocks` as the current directory, generate a
`stock_messages_<locale>.dart` for each `stocks_<locale>.arb` file and
`stock_messages_all.dart`, which imports all of the messages files:
```
flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/i18n \
   --generated-file-prefix=stock_ --no-use-deferred-loading lib/*.dart lib/i18n/stocks_*.arb
```

The `StockStrings` class uses the generated `initializeMessages()`
function (`stock_messages_all.dart`) to load the localized messages
and `Intl.message()` to look them up.
