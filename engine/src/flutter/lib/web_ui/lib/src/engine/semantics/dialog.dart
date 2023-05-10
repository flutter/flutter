// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../dom.dart';
import '../semantics.dart';
import '../util.dart';

/// Provides accessibility for dialogs.
///
/// See also [Role.dialog].
class Dialog extends RoleManager {
  Dialog(SemanticsObject semanticsObject) : super(Role.dialog, semanticsObject);

  @override
  void dispose() {
    semanticsObject.element.removeAttribute('aria-label');
    semanticsObject.clearAriaRole();
  }

  @override
  void update() {
    final String? label = semanticsObject.label;
    assert(() {
      if (label == null || label.trim().isEmpty) {
        printWarning(
          'Semantic node ${semanticsObject.id} was assigned dialog role, but '
          'is missing a label. A dialog should contain a label so that a '
          'screen reader can communicate to the user that a dialog appeared '
          'and a user action is requested.'
        );
      }
      return true;
    }());
    semanticsObject.element.setAttribute('aria-label', label ?? '');
    semanticsObject.setAriaRole('dialog', true);
  }
}
