// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class BrowserInstallerException implements Exception {
  BrowserInstallerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DriverException implements Exception {
  DriverException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ToolException implements Exception {
  ToolException(this.message);

  final String message;

  @override
  String toString() => message;
}
