// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// In order to use this library import the `usage_html.dart` file and
/// instantiate the [AnalyticsHtml] class.
///
/// You'll need to provide a Google Analytics tracking ID, the application name,
/// and the application version.
library usage_html;

export 'src/usage_impl_html.dart' show AnalyticsHtml;
export 'usage.dart';
