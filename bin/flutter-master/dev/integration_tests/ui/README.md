# Flutter UI integration tests

This project contains a collection of non-plugin-dependent UI
integration tests. The device code is in the `lib/` directory, the
driver code is in the `test_driver/` directory. They work together.
Normally they are run via the devicelab.

## keyboard\_resize

Verifies that showing and hiding the keyboard resizes the content.

## routing

Verifies that `flutter drive --route` works correctly.
