// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';

/// Superclass for locale-specific data provided by the application.
class LocaleQueryData { } // TODO(ianh): We need a better type here. This doesn't really make sense.

/// Establishes a subtree in which locale queries resolve to the given data.
class LocaleQuery extends InheritedWidget {
  /// Creates a widget that provides [LocaleQueryData] to its descendants.
  const LocaleQuery({
    Key key,
    @required this.data,
    @required Widget child
  }) : assert(child != null),
       super(key: key, child: child);

  /// The locale data for this subtree.
  final LocaleQueryData data;

  /// The data from the closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// MyLocaleData data = LocaleQueryData.of(context);
  /// ```
  static LocaleQueryData of(BuildContext context) {
    final LocaleQuery query = context.inheritFromWidgetOfExactType(LocaleQuery);
    return query?.data;
  }

  @override
  bool updateShouldNotify(LocaleQuery old) => data != old.data;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$data');
  }
}
