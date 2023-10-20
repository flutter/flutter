// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  LabelAndValue(SemanticsObject semanticsObject, PrimaryRoleManager owner)
      : super(Role.labelAndValue, semanticsObject, owner);

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

    owner.setAttribute('aria-label', combinedValue.toString());
  }

  void _cleanUpDom() {
    owner.removeAttribute('aria-label');
  }

  @override
  void dispose() {
    super.dispose();
    _cleanUpDom();
  }
}
