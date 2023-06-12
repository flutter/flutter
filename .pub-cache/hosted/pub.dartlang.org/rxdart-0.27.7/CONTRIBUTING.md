# Contributing to RxDart

## Create a new issue

The easiest way to get involved is to create a [new issue](https://github.com/ReactiveX/rxdart/issues/new) when you spot a bug, if the documentation is incomplete or out of date, or if you identify an implementation problem.

## General coding guidlines

If you'd like to add a feature or fix a bug, we're more than happy to accept pull requests! We only ask a few things:

  - Ensure your code contains no analyzer errors, e.g.
    - Code is strong-mode compliant
    - Code is free of lint errors
  - Format your code with `dart format`
  - Write tests for all new code paths, consider using the [Stream Matchers](https://pub.dartlang.org/packages/test#stream-matchers) available from the test package.
  - Write helpful documentation
  - If you would like to make a bigger / fundamental change to the codebase, please file a lightweight example PR / issue, or contact us in [Gitter](https://gitter.im/ReactiveX/rxdart) so we can discuss the issue.

## Advice when adding a new Stream

  - Extend from `Stream`
  - Add the new `Stream` to the exported `rx_streams` library
  - If the Stream is not a broadcast stream, ensure it properly enforces the single-subscription contract
  - Ensure the stream closes properly
  - Add new tests to `tests/rxdart_test.dart`

## Advice when adding a new operator

  - Extend from the `StreamTransformer` class so it can be used independently
  - Use the `StreamTransformer` in an `extension` method
  - Add the new `StreamTransformer` to the exported `rx_transformers` library
  - Ensure the `StreamTransformer` can be re-used
  - Add new tests to `tests/rxdart_test.dart`
