To rebuild the i18n files:

```
pub run intl:generate_from_arb \
  --output-dir=lib/i18n \
  --generated-file-prefix=stock_ \
  --no-use-deferred-loading \
  lib/*.dart \
  lib/i18n/*.arb
```
