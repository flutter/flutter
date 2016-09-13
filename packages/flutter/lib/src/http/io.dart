// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

/// Whether `dart:io` is supported on this platform.
bool get supported => true;

/// Asserts that the [name]d `dart:io` feature is supported on this platform.
///
/// If `dart:io` doesn't work on this platform, this throws an
/// [UnsupportedError].
void assertSupported(String name) {}

/// Creates a new `dart:io` HttpClient instance.
newHttpClient() => new io.HttpClient();

/// Creates a new `dart:io` File instance with the given [path].
newFile(String path) => new io.File(path);

/// Returns whether [error] is a `dart:io` HttpException.
bool isHttpException(error) => error is io.HttpException;

/// Returns whether [client] is a `dart:io` HttpClient.
bool isHttpClient(client) => client is io.HttpClient;
