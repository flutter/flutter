# Platform

[![Build Status -](https://travis-ci.org/google/platform.dart.svg?branch=master)](https://travis-ci.org/google/platform.dart)
[![Coverage Status -](https://coveralls.io/repos/github/google/platform.dart/badge.svg?branch=master)](https://coveralls.io/github/google/platform.dart?branch=master)
[![Pub](https://img.shields.io/pub/v/platform.svg)](https://pub.dartlang.org/packages/platform)

A generic platform abstraction for Dart.

Like `dart:io`, `package:platform` supplies a rich, Dart-idiomatic API for
accessing platform-specific information.

`package:platform` provides a lightweight wrapper around the static `Platform`
properties that exist in `dart:io`. However, it uses instance properties rather
than static properties, making it possible to mock out in tests.
