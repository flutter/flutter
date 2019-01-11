# Flutter Analysis Options

This package contains the analysis lints used by the Flutter repositories:

- [The Flutter framework](https://github.com/flutter/flutter)
- [The Flutter engine](https://github.com/flutter/engine)
- [Flutter plugins](https://github.com/flutter/plugins)
- [Flutter packages](https://github.com/flutter/packages)

Other projects are welcome to consume and use these rules as well. It contains
two files:

## analysis_options_base.yaml

This is a subset of rules suitable for most Flutter projects.

## analysis_options.yaml

This imports all of the rules in `analysis_options_base.yaml`, plus additional
rules that conform to the style guidelines for the Flutter repository.

## Consumption

This package can be consumed from the Flutter SDK like so:

```yaml
dependencies:
  flutter_analysis_options:
    sdk: flutter
```
