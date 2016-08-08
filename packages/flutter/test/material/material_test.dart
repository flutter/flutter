// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NotifyMaterial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    new LayoutChangedNotification().dispatch(context);
    return new Container();
  }
}

void main() {
  testWidgets('LayoutChangedNotificaion test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Material(
        child: new NotifyMaterial()
      )
    );
  });
}
