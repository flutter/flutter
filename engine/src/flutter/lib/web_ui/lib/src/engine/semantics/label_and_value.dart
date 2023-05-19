// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import 'semantics.dart';

/// Renders [SemanticsObject.label] and/or [SemanticsObject.value] to the semantics DOM.
///
/// VoiceOver supports "aria-label" but only in conjunction with an ARIA role.
/// Setting "aria-label" on an empty element without a role causes VoiceOver to
/// treat element as if it does not exist. VoiceOver supports role "text", which
/// is a proprietary role not supported by other browsers. Flutter Web still
/// uses it because it provides the best user experience for plain text nodes.
///
/// TalkBack supports standalone "aria-label" attribute, but does not support
/// role "text". This leads to TalkBack reading "group" or "empty group" on
/// plain text elements, but that's still better than other alternatives
/// considered.
///
/// The value is not always rendered. Some semantics nodes correspond to
/// interactive controls, such as an `<input>` element. In such case the value
/// is reported via that element's `value` attribute rather than rendering it
/// separately.
///
/// This role manager does not manage images and text fields. See
/// [ImageRoleManager] and [TextField].
class LabelAndValue extends RoleManager {
  LabelAndValue(SemanticsObject semanticsObject)
      : super(Role.labelAndValue, semanticsObject);

  @override
  void update() {
    final bool hasValue = semanticsObject.hasValue;
    final bool hasLabel = semanticsObject.hasLabel;
    final bool hasTooltip = semanticsObject.hasTooltip;

    // If the node is incrementable the value is reported to the browser via
    // the respective role manager. We do not need to also render it again here.
    final bool shouldDisplayValue = hasValue && !semanticsObject.isIncrementable;

    if (!hasLabel && !shouldDisplayValue && !hasTooltip) {
      _cleanUpDom();
      return;
    }

    final StringBuffer combinedValue = StringBuffer();
    if (hasTooltip) {
      combinedValue.write(semanticsObject.tooltip);
      if (hasLabel || shouldDisplayValue) {
        combinedValue.write('\n');
      }
    }
    if (hasLabel) {
      combinedValue.write(semanticsObject.label);
      if (shouldDisplayValue) {
        combinedValue.write(' ');
      }
    }

    if (shouldDisplayValue) {
      combinedValue.write(semanticsObject.value);
    }

    semanticsObject.element
        .setAttribute('aria-label', combinedValue.toString());

    // Assign one of three roles to the element: heading, group, text.
    //
    // - "group" is used when the node has children, irrespective of whether the
    //   node is marked as a header or not. This is because marking a group
    //   as a "heading" will prevent the AT from reaching its children.
    // - "heading" is used when the framework explicitly marks the node as a
    //   heading and the node does not have children.
    // - "text" is used by default.
    //
    // As of October 24, 2022, "text" only has effect on Safari. Other browsers
    // ignore it. Setting role="text" prevents Safari from treating the element
    // as a "group" or "empty group". Other browsers still announce it as
    // "group" or "empty group". However, other options considered produced even
    // worse results, such as:
    //
    // - Ignore the size of the element and size the focus ring to the text
    //   content, which is wrong. The HTML text size is irrelevant because
    //   Flutter renders into canvas, so the focus ring looks wrong.
    // - Read out the same label multiple times.
    if (semanticsObject.hasChildren) {
      semanticsObject.setAriaRole('group', true);
    } else if (semanticsObject.hasFlag(ui.SemanticsFlag.isHeader)) {
      semanticsObject.setAriaRole('heading', true);
    } else {
      semanticsObject.setAriaRole('text', true);
    }
  }

  void _cleanUpDom() {
    semanticsObject.element.removeAttribute('aria-label');
    semanticsObject.clearAriaRole();
  }

  @override
  void dispose() {
    super.dispose();
    _cleanUpDom();
  }
}
