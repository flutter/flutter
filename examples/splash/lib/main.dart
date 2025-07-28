// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

@MyCustomPreview()
Widget preview() => Text('Foo');

Widget wrapper(Widget widget) => widget;

final class MyCustomPreview implements MultiPreview {
  const MyCustomPreview()
    : previews = const <Preview>[
        Preview(name: 'foo', wrapper: wrapper),
        Preview(name: 'bar'),
        Preview(name: 'baz'),
      ];

  @override
  final List<Preview> previews;
}

final class MyCustomPreview2 implements MultiPreview {
  const MyCustomPreview2({
    required this.foo,
    required String bar,
    required WidgetWrapper wrapper,
  }) : previews = const <Preview>[
         Preview(name: 'prefix:', wrapper: wrapper),
         Preview(name: 'foo: $foo'),
         Preview(name: 'bar: $bar'),
       ];

  final String foo;

  @override
  final List<Preview> previews;
}

void main() {
  runApp(
    const DecoratedBox(
      decoration: BoxDecoration(color: Colors.white),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.ltr,
          children: <Widget>[
            FlutterLogo(size: 48),
            Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'This app is only meant to be run under the Flutter debugger',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
