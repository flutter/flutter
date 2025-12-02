// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('toString control test', (WidgetTester tester) async {
    final Widget widget = Title(
      color: const Color(0xFF00FF00),
      title: 'Awesome app',
      child: Container(),
    );
    expect(widget.toString, isNot(throwsException));
  });

  testWidgets('should handle having no title', (WidgetTester tester) async {
    final widget = Title(color: const Color(0xFF00FF00), child: Container());
    expect(widget.toString, isNot(throwsException));
    expect(widget.title, equals(''));
    expect(widget.color, equals(const Color(0xFF00FF00)));
  });

  testWidgets('should not allow non-opaque color', (WidgetTester tester) async {
    expect(() => Title(color: const Color(0x00000000), child: Container()), throwsAssertionError);
  });

  testWidgets('should not pass "null" to setApplicationSwitcherDescription', (
    WidgetTester tester,
  ) async {
    final log = <MethodCall>[];

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      MethodCall methodCall,
    ) async {
      log.add(methodCall);
      return null;
    });

    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(Title(color: const Color(0xFF00FF00), child: Container()));

    expect(log, hasLength(1));
    expect(
      log.single,
      isMethodCall(
        'SystemChrome.setApplicationSwitcherDescription',
        arguments: <String, dynamic>{'label': '', 'primaryColor': 4278255360},
      ),
    );
  });

  testWidgets(
    'should call setApplicationSwitcherDescription once when widget is rebuilt with same values',
    (WidgetTester tester) async {
      final log = <MethodCall>[];

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        MethodCall methodCall,
      ) async {
        log.add(methodCall);
        return null;
      });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      final title = Title(color: const Color(0xFF00FF00), child: Container());

      await tester.pumpWidget(title);
      await tester.pumpWidget(title);
      await tester.pumpWidget(title);

      expect(log, hasLength(1));
      expect(
        log.single,
        isMethodCall(
          'SystemChrome.setApplicationSwitcherDescription',
          arguments: <String, dynamic>{'label': '', 'primaryColor': 4278255360},
        ),
      );
    },
  );

  testWidgets(
    'should call setApplicationSwitcherDescription again only when title or color changes',
    (WidgetTester tester) async {
      final log = <MethodCall>[];

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
        MethodCall methodCall,
      ) async {
        log.add(methodCall);
        return null;
      });

      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      final title = Title(title: 'title', color: const Color(0xFF00FF00), child: Container());
      final title2 = Title(title: 'title2', color: const Color(0xFF00FF02), child: Container());

      await tester.pumpWidget(title);
      await tester.pumpWidget(title);
      await tester.pumpWidget(title2);
      await tester.pumpWidget(title2);

      expect(log, hasLength(2));
      expect(
        log.first,
        isMethodCall(
          'SystemChrome.setApplicationSwitcherDescription',
          arguments: <String, dynamic>{'label': 'title', 'primaryColor': 4278255360},
        ),
      );
      expect(
        log.last,
        isMethodCall(
          'SystemChrome.setApplicationSwitcherDescription',
          arguments: <String, dynamic>{'label': 'title2', 'primaryColor': 4278255362},
        ),
      );
    },
  );
}
