// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

import 'semantics_tester.dart';

void main() {
  testWidgets('canDrag update does not trigger assert in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    await tester.pumpWidget(buildTestWidget(
      excludeListSemantics: false,
      listIsDragable: true,
      numOfListEntries: 100,
    ));

    // The following should not trigger an assert.
    await tester.pumpWidget(buildTestWidget(
      excludeListSemantics: true,
      listIsDragable: false,
      numOfListEntries: 2,
    ));

    semantics.dispose();
  });
}

Widget buildTestWidget({
    @required bool excludeListSemantics,
    @required bool listIsDragable,
    @required int numOfListEntries
}) {
  final List<Widget> children = new List<Widget>.generate(numOfListEntries, (int i) {
    return new Container(
      child: new Semantics(
        label: 'child$i',
      ),
      height: 40.0,
    );
  });

  return new Semantics(
    container: true,
    label: 'container',
    child: new ExcludeSemantics(
      excluding: excludeListSemantics,
      child: new ListView(
        physics: listIsDragable ? null : const NeverScrollableScrollPhysics(),
        children: children,
      ),
    ),
  );
}
