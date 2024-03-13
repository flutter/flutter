// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../dom.dart';
import 'semantics.dart';

/// The method used to represend a label of a leaf node in the DOM.
///
/// This is required by some screen readers and web crawlers.
///
/// Container nodes only use `aria-label`, even if [domText] is chosen. This is
/// because screen readers treat container nodes as "groups" of other nodes, and
/// respect the `aria-label` without a [DomText] node. Crawlers typically do not
/// need this information, as they primarily scan visible text, which is
/// communicated in semantics as leaf text and heading nodes.
enum LeafLabelRepresentation {
  /// Represents the label as an `aria-label` attribute.
  ariaLabel,

  /// Represents the label as a [DomText] node.
  domText,
}

/// Renders [SemanticsObject.label] and/or [SemanticsObject.value] to the semantics DOM.
///
/// The value is not always rendered. Some semantics nodes correspond to
/// interactive controls. In such case the value is reported via that element's
/// `value` attribute rather than rendering it separately.
class LabelAndValue extends RoleManager {
  LabelAndValue(SemanticsObject semanticsObject, PrimaryRoleManager owner, { required this.labelRepresentation })
      : super(Role.labelAndValue, semanticsObject, owner);

  /// Configures the representation of the label in the DOM.
  final LeafLabelRepresentation labelRepresentation;

  @override
  void update() {
    final String? computedLabel = _computeLabel();

    if (computedLabel == null) {
      _oldLabel = null;
      _cleanUpDom();
      return;
    }

    _updateLabel(computedLabel);
  }

  DomText? _domText;
  String? _oldLabel;

  void _updateLabel(String label) {
    if (label == _oldLabel) {
      return;
    }
    _oldLabel = label;

    final bool needsDomText = labelRepresentation == LeafLabelRepresentation.domText && !semanticsObject.hasChildren;

    _domText?.remove();
    if (needsDomText) {
      owner.removeAttribute('aria-label');
      final DomText domText = domDocument.createTextNode(label);
      _domText = domText;
      semanticsObject.element.appendChild(domText);
    } else {
      owner.setAttribute('aria-label', label);
      _domText = null;
    }
  }

  String? _computeLabel() {
    final bool hasValue = semanticsObject.hasValue;
    final bool hasLabel = semanticsObject.hasLabel;
    final bool hasTooltip = semanticsObject.hasTooltip;

    // If the node is incrementable the value is reported to the browser via
    // the respective role manager. We do not need to also render it again here.
    final bool shouldDisplayValue = hasValue && !semanticsObject.isIncrementable;

    if (!hasLabel && !shouldDisplayValue && !hasTooltip) {
      return null;
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

    return combinedValue.toString();
  }

  void _cleanUpDom() {
    owner.removeAttribute('aria-label');
    _domText?.remove();
  }

  @override
  void dispose() {
    super.dispose();
    _cleanUpDom();
  }
}
