// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(yjbanov): TalkBack on Android incorrectly reads state changes for radio
//                buttons. When checking a radio button it reads
//                "Checked, not checked". This is likely due to another radio
//                button automatically becoming unchecked. VoiceOver reads it
//                correctly. It is possible we can fix this by using
//                "radiogroup" and "aria-owns". This may require a change in the
//                framework. Currently the framework does not report the
//                grouping of radio buttons.

part of engine;

/// The specific type of checkable control.
enum _CheckableKind {
  /// A checkbox.
  checkbox,

  /// A radio button, defined by [ui.SemanticsFlag.isInMutuallyExclusiveGroup].
  radio,
}

/// Renders semantics objects that have checked state.
///
/// See also [ui.SemanticsFlag.hasCheckedState], [ui.SemanticsFlag.isChecked],
/// and [ui.SemanticsFlag.isInMutuallyExclusiveGroup].
class Checkable extends RoleManager {
  _CheckableKind _kind;

  Checkable(SemanticsObject semanticsObject)
      : super(Role.checkable, semanticsObject) {
    if (semanticsObject.hasFlag(ui.SemanticsFlag.isInMutuallyExclusiveGroup)) {
      _kind = _CheckableKind.radio;
    } else {
      _kind = _CheckableKind.checkbox;
    }
  }

  @override
  void update() {
    if (semanticsObject.isFlagsDirty) {
      switch (_kind) {
        case _CheckableKind.checkbox:
          semanticsObject.setAriaRole('checkbox', true);
          break;
        case _CheckableKind.radio:
          semanticsObject.setAriaRole('radio', true);
          break;
      }

      semanticsObject.element.setAttribute(
        'aria-checked',
        semanticsObject.hasFlag(ui.SemanticsFlag.isChecked) ? 'true' : 'false',
      );
    }
  }

  @override
  void dispose() {
    switch (_kind) {
      case _CheckableKind.checkbox:
        semanticsObject.setAriaRole('checkbox', false);
        break;
      case _CheckableKind.radio:
        semanticsObject.setAriaRole('radio', false);
        break;
    }
  }
}
