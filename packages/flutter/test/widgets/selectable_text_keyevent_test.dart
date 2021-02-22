// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('!chrome')
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class MockClipboard {
  dynamic _clipboardData = <String, dynamic>{
    'text': null,
  };

  Future<dynamic> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return _clipboardData;
      case 'Clipboard.setData':
        _clipboardData = methodCall.arguments;
        break;
    }
  }
}

class MaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) => DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(MaterialLocalizationsDelegate old) => false;
}

class WidgetsLocalizationsDelegate extends LocalizationsDelegate<WidgetsLocalizations> {
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) => DefaultWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(WidgetsLocalizationsDelegate old) => false;
}

Widget overlay({ Widget? child }) {
  final OverlayEntry entry = OverlayEntry(
    builder: (BuildContext context) {
      return Center(
        child: Material(
          child: child,
        ),
      );
    },
  );
  return overlayWithEntry(entry);
}

Widget overlayWithEntry(OverlayEntry entry) {
  return Localizations(
    locale: const Locale('en', 'US'),
    delegates: <LocalizationsDelegate<dynamic>>[
      WidgetsLocalizationsDelegate(),
      MaterialLocalizationsDelegate(),
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800.0, 600.0)),
        child: Overlay(
          initialEntries: <OverlayEntry>[
            entry,
          ],
        ),
      ),
    ),
  );
}

Widget boilerplate({ Widget? child }) {
  return Localizations(
    locale: const Locale('en', 'US'),
    delegates: <LocalizationsDelegate<dynamic>>[
      WidgetsLocalizationsDelegate(),
      MaterialLocalizationsDelegate(),
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(800.0, 600.0)),
        child: Center(
          child: Material(
            child: child,
          ),
        ),
      ),
    ),
  );
}

Future<void> skipPastScrollingAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

double getOpacity(WidgetTester tester, Finder finder) {
  return tester.widget<FadeTransition>(
      find.ancestor(
        of: finder,
        matching: find.byType(FadeTransition),
      ),
  ).opacity.value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockClipboard mockClipboard = MockClipboard();
  SystemChannels.platform.setMockMethodCallHandler(mockClipboard.handleMethodCall);

  const String kThreeLines =
      'First line of text is\n'
      'Second line goes until\n'
      'Third line of stuff';
  const String kMoreThanFourLines =
      kThreeLines +
          "\nFourth line won't display and ends at";

  // Returns the first RenderEditable.
  RenderEditable findRenderEditable(WidgetTester tester) {
    final RenderObject root = tester.renderObject(find.byType(EditableText));
    expect(root, isNotNull);

    late RenderEditable renderEditable;
    void recursiveFinder(RenderObject child) {
      if (child is RenderEditable) {
        renderEditable = child;
        return;
      }
      child.visitChildren(recursiveFinder);
    }
    root.visitChildren(recursiveFinder);
    expect(renderEditable, isNotNull);
    return renderEditable;
  }

  List<TextSelectionPoint> globalize(Iterable<TextSelectionPoint> points, RenderBox box) {
    return points.map<TextSelectionPoint>((TextSelectionPoint point) {
      return TextSelectionPoint(
        box.localToGlobal(point.point),
        point.direction,
      );
    }).toList();
  }

  setUp(() {
    debugResetSemanticsIdCounter();
  });

  Widget selectableTextBuilder({
    String text = '',
    int? maxLines = 1,
    int? minLines,
  }) {
    return boilerplate(
      child: SelectableText(
        text,
        style: const TextStyle(color: Colors.black, fontSize: 34.0),
        maxLines: maxLines,
        minLines: minLines,
      ),
    );
  }

  group('Keyboard Tests', () {
    late TextEditingController controller;

    Future<void> setupWidget(WidgetTester tester, String text) async {
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: RawKeyboardListener(
              focusNode: focusNode,
              onKey: null,
              child: SelectableText(
                text,
                maxLines: 3,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(SelectableText));
      await tester.pumpAndSettle();
      final EditableText editableTextWidget = tester.widget(find.byType(EditableText).first);
      controller = editableTextWidget.controller;
    }

    testWidgets('Shift test 1', (WidgetTester tester) async {
      await setupWidget(tester, 'a big house');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft, physicalKey: PhysicalKeyboardKey.shiftLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft, physicalKey: PhysicalKeyboardKey.arrowLeft);
      expect(controller.selection.extentOffset - controller.selection.baseOffset, -1);
    });

  //   testWidgets('Shift test 2', (WidgetTester tester) async {
  //     await setupWidget(tester, 'abcdefghi');

  //     controller.selection = const TextSelection.collapsed(offset: 3);
  //     await tester.pump();

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
  //     await tester.pumpAndSettle();
  //     expect(controller.selection.extentOffset - controller.selection.baseOffset, 1);
  //   });

  //   testWidgets('Control Shift test', (WidgetTester tester) async {
  //     await setupWidget(tester, 'their big house');

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);

  //     await tester.pumpAndSettle();

  //     expect(controller.selection.extentOffset - controller.selection.baseOffset, -5);
  //   });

  //   testWidgets('Down and up test', (WidgetTester tester) async {
  //     await setupWidget(tester, 'a big house');

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.pumpAndSettle();

  //     expect(controller.selection.extentOffset - controller.selection.baseOffset, -11);

  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();

  //     expect(controller.selection.extentOffset - controller.selection.baseOffset, 0);
  //   });

  //   testWidgets('Down and up test 2', (WidgetTester tester) async {
  //     await setupWidget(tester, 'a big house\njumped over a mouse\nOne more line yay');

  //     controller.selection = const TextSelection.collapsed(offset: 0);
  //     await tester.pump();

  //     for (int i = 0; i < 5; i += 1) {
  //       await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  //       await tester.pumpAndSettle();
  //     }
  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(controller.selection.extentOffset - controller.selection.baseOffset, 12);

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(controller.selection.extentOffset - controller.selection.baseOffset, 32);

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(controller.selection.extentOffset - controller.selection.baseOffset, 12);

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(controller.selection.extentOffset - controller.selection.baseOffset, 0);

  //     await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  //     await tester.pumpAndSettle();
  //     await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //     await tester.pumpAndSettle();

  //     expect(controller.selection.extentOffset - controller.selection.baseOffset, -5);
  //   });
  // });

  // testWidgets('Copy test', (WidgetTester tester) async {
  //   final FocusNode focusNode = FocusNode();

  //   String clipboardContent = '';
  //   SystemChannels.platform.setMockMethodCallHandler((MethodCall methodCall) async {
  //     if (methodCall.method == 'Clipboard.setData')
  //       clipboardContent = methodCall.arguments['text'] as String;
  //     else if (methodCall.method == 'Clipboard.getData')
  //       return <String, dynamic>{'text': clipboardContent};
  //     return null;
  //   });
  //   const String testValue = 'a big house\njumped over a mouse';
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: null,
  //           child: const SelectableText(
  //             testValue,
  //             maxLines: 3,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   final EditableText editableTextWidget = tester.widget(find.byType(EditableText).first);
  //   final TextEditingController controller = editableTextWidget.controller;
  //   focusNode.requestFocus();
  //   await tester.pump();

  //   await tester.tap(find.byType(SelectableText));
  //   await tester.pumpAndSettle();

  //   controller.selection = const TextSelection.collapsed(offset: 0);
  //   await tester.pump();

  //   // Select the first 5 characters
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  //     await tester.pumpAndSettle();
  //   }
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

  //   // Copy them
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.controlRight);
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.controlRight);
  //   await tester.pumpAndSettle();

  //   expect(clipboardContent, 'a big');

  //   await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  //   await tester.pumpAndSettle();
  // });

  // testWidgets('Select all test', (WidgetTester tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   const String testValue = 'a big house\njumped over a mouse';
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: null,
  //           child: const SelectableText(
  //             testValue,
  //             maxLines: 3,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   final EditableText editableTextWidget = tester.widget(find.byType(EditableText).first);
  //   final TextEditingController controller = editableTextWidget.controller;
  //   focusNode.requestFocus();
  //   await tester.pump();

  //   await tester.tap(find.byType(SelectableText));
  //   await tester.pumpAndSettle();

  //   // Select All
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  //   await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  //   await tester.pumpAndSettle();

  //   expect(controller.selection.baseOffset, 0);
  //   expect(controller.selection.extentOffset, 31);
  // });

  // testWidgets('keyboard selection should call onSelectionChanged', (WidgetTester tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   TextSelection? newSelection;
  //   const String testValue = 'a big house\njumped over a mouse';
  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home: Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: null,
  //           child: SelectableText(
  //             testValue,
  //             maxLines: 3,
  //             onSelectionChanged: (TextSelection selection, SelectionChangedCause? cause) {
  //               expect(newSelection, isNull);
  //               newSelection = selection;
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //   final EditableText editableTextWidget = tester.widget(find.byType(EditableText).first);
  //   final TextEditingController controller = editableTextWidget.controller;
  //   focusNode.requestFocus();
  //   await tester.pump();

  //   await tester.tap(find.byType(SelectableText));
  //   await tester.pumpAndSettle();
  //   expect(newSelection!.baseOffset, 31);
  //   expect(newSelection!.extentOffset, 31);
  //   newSelection = null;

  //   controller.selection = const TextSelection.collapsed(offset: 0);
  //   await tester.pump();

  //   // Select the first 5 characters
  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
  //     await tester.pumpAndSettle();
  //     expect(newSelection!.baseOffset, 0);
  //     expect(newSelection!.extentOffset, i + 1);
  //     newSelection = null;
  //   }
  // });

  // testWidgets('Changing positions of selectable text', (WidgetTester tester) async {
  //   final FocusNode focusNode = FocusNode();
  //   final List<RawKeyEvent> events = <RawKeyEvent>[];

  //   final Key key1 = UniqueKey();
  //   final Key key2 = UniqueKey();

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home:
  //       Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: events.add,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: <Widget>[
  //               SelectableText(
  //                 'a big house',
  //                 key: key1,
  //                 maxLines: 3,
  //               ),
  //               SelectableText(
  //                 'another big house',
  //                 key: key2,
  //                 maxLines: 3,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   EditableText editableTextWidget = tester.widget(find.byType(EditableText).first);
  //   TextEditingController c1 = editableTextWidget.controller;

  //   await tester.tap(find.byType(EditableText).first);
  //   await tester.pumpAndSettle();

  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
  //     await tester.pumpAndSettle();
  //   }
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //   await tester.pumpAndSettle();

  //   expect(c1.selection.extentOffset - c1.selection.baseOffset, -5);

  //   await tester.pumpWidget(
  //     MaterialApp(
  //       home:
  //       Material(
  //         child: RawKeyboardListener(
  //           focusNode: focusNode,
  //           onKey: events.add,
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.stretch,
  //             children: <Widget>[
  //               SelectableText(
  //                 'another big house',
  //                 key: key2,
  //                 maxLines: 3,
  //               ),
  //               SelectableText(
  //                 'a big house',
  //                 key: key1,
  //                 maxLines: 3,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  //   for (int i = 0; i < 5; i += 1) {
  //     await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
  //   }
  //   await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  //   await tester.pumpAndSettle();

  //   editableTextWidget = tester.widget(find.byType(EditableText).last);
  //   c1 = editableTextWidget.controller;

  //   expect(c1.selection.extentOffset - c1.selection.baseOffset, -6);
  // });
  });
}
