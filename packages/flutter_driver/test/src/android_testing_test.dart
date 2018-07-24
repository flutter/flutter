
import 'package:flutter_driver/android_testing.dart';

import 'package:test/test.dart';

// JSON matching and serialized Android AccessibilityNodeInfo.
const String source = r'''
{
  "id": 23,
  "flags": {
    "isChecked": false,
    "isCheckable": false,
    "isEditable": false,
    "isFocusable": false,
    "isFocused": false,
    "isPassword": false,
    "isLongClickable": false
  },
  "text": "hello",
  "className": "android.view.View",
  "rect": {
    "left": 0,
    "top": 0,
    "right": 10,
    "bottom": 10
  },
  "actions": [1, 2, 4]
}
''';

void main() {
  group(AndroidSemanticsNode, () {
    test('can be parsed from json data', () {
      final AndroidSemanticsNode node = AndroidSemanticsNode.deserialize(source);

      expect(node.isChecked, false);
      expect(node.isCheckable, false);
      expect(node.isEditable, false);
      expect(node.isFocusable, false);
      expect(node.isFocused, false);
      expect(node.isPassword, false);
      expect(node.isLongClickable, false);
      expect(node.text, 'hello');
      expect(node.id, 23);
      expect(node.getRect(), const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0));
      expect(node.getActions(), <AndroidSemanticsAction>[
        AndroidSemanticsAction.focus,
        AndroidSemanticsAction.clearFocus,
        AndroidSemanticsAction.select,
      ]);
      expect(node.className, 'android.view.View');
      expect(node.getSize(), const Size(10.0, 10.0));
    });
  });

  group(AndroidSemanticsAction, () {
    test('can be parsed from correct constant id', () {
      expect(AndroidSemanticsAction.deserialize(0x1), AndroidSemanticsAction.focus);
    });

    test('fails if passed a bogus id', () {
      expect(() => AndroidSemanticsAction.deserialize(23),
        throwsA(const isInstanceOf<UnsupportedError>()));
    });
  });

  group('hasAndroidSemantics', () {
    test('matches all android semantics properties', () {
      final AndroidSemanticsNode node = AndroidSemanticsNode.deserialize(source);

      expect(node, hasAndroidSemantics(
        isChecked: false,
        isCheckable: false,
        isEditable: false,
        isFocusable: false,
        isFocused: false,
        isPassword: false,
        isLongClickable: false,
        text: 'hello',
        className: 'android.view.View',
        id: 23,
        rect:  const Rect.fromLTRB(0.0, 0.0, 10.0, 10.0),
        actions: <AndroidSemanticsAction>[
          AndroidSemanticsAction.focus,
          AndroidSemanticsAction.clearFocus,
          AndroidSemanticsAction.select,
        ],
        size: const Size(10.0, 10.0),
      ));
    });
  });
}