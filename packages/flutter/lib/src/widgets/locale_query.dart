// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

// Superclass for locale-specific data provided by the application.
class LocaleQueryData { }

class LocaleQuery<T extends LocaleQueryData> extends InheritedWidget {
  LocaleQuery({
    Key key,
    this.data,
    Widget child
  }) : super(key: key, child: child) {
    assert(child != null);
  }

  final T data;

  static LocaleQueryData of(BuildContext context) {
    LocaleQuery query = context.inheritFromWidgetOfType(LocaleQuery);
    return query == null ? null : query.data;
  }

  bool updateShouldNotify(LocaleQuery old) => data != old.data;

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$data');
  }
}
