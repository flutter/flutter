# Process

[![Build Status -](https://travis-ci.org/google/process.dart.svg?branch=master)](https://travis-ci.org/google/process.dart)
[![Coverage Status -](https://coveralls.io/repos/github/google/process.dart/badge.svg?branch=master)](https://coveralls.io/github/google/process.dart?branch=master)

A generic process invocation abstraction for Dart.

Like `dart:io`, `package:process` supplies a rich, Dart-idiomatic API for
spawning OS processes.

Unlike `dart:io`, `package:process`:

- Can be used to implement custom process invocation backends.
- Comes with a record-replay implementation out-of-the-box, making it super
  easy to test code that spawns processes in a hermetic way.
