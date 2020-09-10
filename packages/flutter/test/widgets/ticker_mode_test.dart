// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Nested TickerMode cannot turn tickers back on', (WidgetTester tester) async {
    int outerTickCount = 0;
    int innerTickCount = 0;

    Widget nestedTickerModes({bool innerEnabled, bool outerEnabled}) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: TickerMode(
          enabled: outerEnabled,
          child: Row(
            children: <Widget>[
              _TickingWidget(
                onTick: () {
                  outerTickCount++;
                },
              ),
              TickerMode(
                enabled: innerEnabled,
                child: _TickingWidget(
                  onTick: () {
                    innerTickCount++;
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(
      nestedTickerModes(
        outerEnabled: false,
        innerEnabled: true,
      ),
    );

    expect(outerTickCount, 0);
    expect(innerTickCount, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(outerTickCount, 0);
    expect(innerTickCount, 0);

    await tester.pumpWidget(
      nestedTickerModes(
        outerEnabled: true,
        innerEnabled: false,
      ),
    );
    outerTickCount = 0;
    innerTickCount = 0;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(outerTickCount, 4);
    expect(innerTickCount, 0);

    await tester.pumpWidget(
      nestedTickerModes(
        outerEnabled: true,
        innerEnabled: true,
      ),
    );
    outerTickCount = 0;
    innerTickCount = 0;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(outerTickCount, 4);
    expect(innerTickCount, 4);

    await tester.pumpWidget(
      nestedTickerModes(
        outerEnabled: false,
        innerEnabled: false,
      ),
    );
    outerTickCount = 0;
    innerTickCount = 0;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(outerTickCount, 0);
    expect(innerTickCount, 0);
  });
}

class _TickingWidget extends StatefulWidget {
  const _TickingWidget({this.onTick});

  final VoidCallback onTick;

  @override
  State<_TickingWidget> createState() => _TickingWidgetState();
}

class _TickingWidgetState extends State<_TickingWidget> with SingleTickerProviderStateMixin {
  Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration _) {
      widget.onTick();
    })..start();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
