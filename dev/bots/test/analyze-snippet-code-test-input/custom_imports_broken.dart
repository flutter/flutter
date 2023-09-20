// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is used by ../analyze_snippet_code_test.dart, which depends on the
// precise contents (including especially the comments) of this file.

// Examples can assume:
// import 'package:flutter/rendering.dart';

/// no error: rendering library was imported.
/// ```dart
/// print(RenderObject);
/// ```
String? bar;

/// error: widgets library was not imported (not even implicitly).
/// ```dart
/// print(Widget); // error (undefined_identifier)
/// ```
String? foo;
