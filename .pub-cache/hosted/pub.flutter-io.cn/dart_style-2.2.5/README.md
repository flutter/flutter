The dart_style package defines an automatic, opinionated formatter for Dart
code. It replaces the whitespace in your program with what it deems to be the
best formatting for it. Resulting code should follow the [Dart style guide][]
but, moreso, should look nice to most human readers, most of the time.

[dart style guide]: https://dart.dev/guides/language/effective-dart/style

The formatter handles indentation, inline whitespace, and (by far the most
difficult) intelligent line wrapping. It has no problems with nested
collections, function expressions, long argument lists, or otherwise tricky
code.

The formatter turns code like this:

```dart
// BEFORE formatting
if (tag=='style'||tag=='script'&&(type==null||type == TYPE_JS
      ||type==TYPE_DART)||
  tag=='link'&&(rel=='stylesheet'||rel=='import')) {}
```

into:

```dart
// AFTER formatting
if (tag == 'style' ||
  tag == 'script' &&
      (type == null || type == TYPE_JS || type == TYPE_DART) ||
  tag == 'link' && (rel == 'stylesheet' || rel == 'import')) {}
```

The formatter will never break your code&mdash;you can safely invoke it
automatically from build and presubmit scripts.

## Style fixes

The formatter can also apply non-whitespace changes to make your code
consistently idiomatic. You must opt into these by passing either `--fix` which
applies all style fixes, or any of the `--fix-`-prefixed flags to apply specific
fixes.

For example, running with `--fix-named-default-separator` changes this:

```dart
greet(String name, {String title: "Captain"}) {
  print("Greetings, $title $name!");
}
```

into:

```dart
greet(String name, {String title = "Captain"}) {
  print("Greetings, $title $name!");
}
```

## Using the formatter

The formatter is part of the unified [`dart`][] developer tool included in the
Dart SDK, so most users get it directly from there. That has the latest version
of the formatter that was available when the SDK was released.

[`dart`]: https://dart.dev/tools/dart-tool

IDEs and editors that support Dart usually provide easy ways to run the
formatter. For example, in WebStorm you can right-click a .dart file and then
choose **Reformat with Dart Style**.

Here's a simple example of using the formatter on the command line:

    $ dart format test.dart

This command formats the `test.dart` file and writes the result to the
file.

`dart format` takes a list of paths, which can point to directories or files. If
the path is a directory, it processes every `.dart` file in that directory or
any of its subdirectories.

By default, it formats each file and write the formatting changes to the files.
If you pass `--output show`, it prints the formatted code to stdout.

You may pass a `-l` option to control the width of the page that it wraps lines
to fit within, but you're strongly encouraged to keep the default line length of
80 columns.

### Validating files

If you want to use the formatter in something like a [presubmit script][] or
[commit hook][], you can pass flags to omit writing formatting changes to disk
and to update the exit code to indicate success/failure:

    $ dart format --output=none --set-exit-if-changed .

## Running other versions of the formatter CLI command

If you need to run a different version of the formatter, you can
[globally activate][] the package from the dart_style package on
pub.dev:

[globally activate]: https://dart.dev/tools/pub/cmd/pub-global

    $ pub global activate dart_style
    $ pub global run dart_style:format ...

## Using the dart_style API

The package also exposes a single dart_style library containing a programmatic
API for formatting code. Simple usage looks like this:

```dart
import 'package:dart_style/dart_style.dart';

main() {
  final formatter = DartFormatter();

  try {
    print(formatter.format("""
    library an_entire_compilation_unit;

    class SomeClass {}
    """));

    print(formatter.formatStatement("aSingle(statement);"));
  } on FormatterException catch (ex) {
    print(ex);
  }
}
```

## Other resources

* Before sending an email, see if you are asking a
  [frequently asked question][faq].

* Before filing a bug, or if you want to understand how work on the
  formatter is managed, see how we [track issues][].

[faq]: https://github.com/dart-lang/dart_style/wiki/FAQ
[track issues]: https://github.com/dart-lang/dart_style/wiki/Tracking-issues
