// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// In order to use this library import the `usage_io.dart` file and
/// instantiate the [AnalyticsIO] class.
///
/// You'll need to provide a Google Analytics tracking ID, the application name,
/// and the application version.
library usage_io;

export 'src/usage_impl_io.dart' show AnalyticsIO;
export 'usage.dart';
