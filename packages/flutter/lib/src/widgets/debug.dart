// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'media_query.dart';

bool debugCheckHasMediaQuery(BuildContext context) {
  assert(() {
    if (MediaQuery.of(context) == null) {
      Element element = context;
      throw new FlutterError(
        'No MediaQuery widget found.\n'
        '${element.widget.runtimeType} widgets require a MediaQuery widget ancestor.\n'
        'The specific widget that could not find a MediaQuery ancestor was:\n'
        '  ${element.widget}'
        'The ownership chain for the affected widget is:\n'
        '  ${element.debugGetOwnershipChain(10)}'
      );
    }
    return true;
  });
  return true;
}
