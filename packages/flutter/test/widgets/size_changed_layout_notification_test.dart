// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class NotifyMaterial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    new LayoutChangedNotification().dispatch(context);
    return new Container();
  }
}

void main() {
  testWidgets('SizeChangedLayoutNotification test', (WidgetTester tester) async {
    bool notified = false;

    await tester.pumpWidget(
      new Center(
        child: new NotificationListener<LayoutChangedNotification>(
          onNotification: (LayoutChangedNotification notification) {
            throw new Exception('Should not reach this point.');
          },
          child: const SizeChangedLayoutNotifier(
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      new Center(
        child: new NotificationListener<LayoutChangedNotification>(
          onNotification: (LayoutChangedNotification notification) {
            expect(notification, const isInstanceOf<SizeChangedLayoutNotification>());
            notified = true;
            return true;
          },
          child: const SizeChangedLayoutNotifier(
            child: const SizedBox(
              width: 200.0,
              height: 100.0,
            ),
          ),
        ),
      ),
    );

    expect(notified, isTrue);
  });
}
