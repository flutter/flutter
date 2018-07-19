import 'package:test/test.dart';
import 'package:flutter/semantics.dart';

void main() {
  group(CustomAccessibilityAction, () {

    test('is provided a canonical id based on the label', () {
      final CustomAccessibilityAction action1 = new CustomAccessibilityAction(label: _nonconst('test'));
      final CustomAccessibilityAction action2 = new CustomAccessibilityAction(label: _nonconst('test'));
      final CustomAccessibilityAction action3 = new CustomAccessibilityAction(label: _nonconst('not test'));
      final int id1 = CustomAccessibilityAction.getIdentifier(action1);
      final int id2 = CustomAccessibilityAction.getIdentifier(action2);
      final int id3 = CustomAccessibilityAction.getIdentifier(action3);

      expect(id1, id2);
      expect(id2, isNot(id3));
      expect(CustomAccessibilityAction.getAction(id1), action1);
      expect(CustomAccessibilityAction.getAction(id2), action1);
      expect(CustomAccessibilityAction.getAction(id3), action3);
    });

  });
}

T _nonconst<T>(T value) => value;
