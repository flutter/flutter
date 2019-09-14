// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('BuildOwner.isBuilding is true inside didChangeDependencies/build and false otherwise',
    (WidgetTester tester) async {
      expect(tester.binding.buildOwner.isBuilding, isFalse);

      await tester.pumpWidget(
        _Stateful(
          didChangeDependencies: () {
            expect(tester.binding.buildOwner.isBuilding, isTrue);
          },
          builder: (BuildContext _) {
            expect(tester.binding.buildOwner.isBuilding, isTrue);
            return Container();
          },
        ),
      );

      expect(tester.binding.buildOwner.isBuilding, isFalse);
    },
  );
}

class _Stateful extends StatefulWidget {
  const _Stateful({Key key, this.didChangeDependencies, this.builder}) : super(key: key);

  final VoidCallback didChangeDependencies;
  final WidgetBuilder builder;

  @override
  _StatefulState createState() => _StatefulState();
}

class _StatefulState extends State<_Stateful> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.didChangeDependencies?.call();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}