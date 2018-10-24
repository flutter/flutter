// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/src/material/dialog_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Custom dialog shape', (WidgetTester tester) async {
    const RoundedRectangleBorder customBorder =
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0)));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(dialogTheme: const DialogTheme(shape: customBorder)),
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return Center(
                child: RaisedButton(
                  child: const Text('X'),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (BuildContext context) {
                        return const AlertDialog(
                          title: Text('Title'),
                          content: Text('Y'),
                          actions: <Widget>[ ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1));

    final StatefulElement widget = tester.element(find.byType(Material).last);
    final Material materialWidget = widget.state.widget;
    //first and second expect check that the material is the dialog's one
    expect(materialWidget.type, MaterialType.card);
    expect(materialWidget.elevation, 24);
    expect(materialWidget.shape, customBorder);
  });
}