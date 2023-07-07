[![Pub Package](https://img.shields.io/pub/v/boolean_selector.svg)](https://pub.dev/packages/boolean_selector)
[![Build Status](https://travis-ci.org/dart-lang/boolean_selector.svg?branch=master)](https://travis-ci.org/dart-lang/boolean_selector)

The `boolean_selector` package defines a simple and flexible syntax for boolean
expressions. It can be used for filtering based on user-defined expressions. For
example, the [`test`][test] package uses boolean selectors to allow users to
define what platforms their tests support.

[test]: https://github.com/dart-lang/test

The boolean selector syntax is based on a simplified version of Dart's
expression syntax. Selectors can contain identifiers, parentheses, and boolean
operators, including `||`, `&&`, `!`, and `? :`. Any valid Dart identifier is
allowed, and identifiers may also contain hyphens. For example, `chrome`,
`chrome || content-shell`, and `js || (vm && linux)` are all valid boolean
selectors.

A boolean selector is parsed from a string using
[`BooleanSelector.parse()`][parse], and evaluated against a set of variables
using [`BooleanSelector.evaluate()`][evaluate]. The variables are supplied as
a function that takes a variable name and returns its value. For example:

[parse]: https://pub.dev/documentation/boolean_selector/latest/boolean_selector/BooleanSelector/BooleanSelector.parse.html

[evaluate]: https://pub.dev/documentation/boolean_selector/latest/boolean_selector/BooleanSelector/evaluate.html

```dart
import 'package:boolean_selector/boolean_selector.dart';

void main(List<String> args) {
  var selector = BooleanSelector.parse("(x && y) || z");
  print(selector.evaluate((variable) => args.contains(variable)));
}
```

## Versioning

If this package adds new features to the boolean selector syntax, it will
increment its major version number. This ensures that packages that expose the
syntax to their users will be able to update their own minor versions, so their
users can indicate that they rely on the new syntax.
