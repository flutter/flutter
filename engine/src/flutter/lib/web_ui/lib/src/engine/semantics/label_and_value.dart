// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// Renders [_label] and [_value] to the semantics DOM.
///
/// The rendering method is browser-dependent. There is no explicit ARIA
/// attribute to express "value". Instead, you are expected to render the
/// value as text content of HTML.
///
/// VoiceOver only supports "aria-label" for certain ARIA roles. For plain
/// text it expects that the label is part of the text content of the element.
/// The strategy for VoiceOver is to combine [_label] and [_value] and stamp
/// out a single child element that contains the value.
///
/// TalkBack supports the "aria-label" attribute. However, when present,
/// TalkBack ignores the text content. Therefore, we cannot split [_label]
/// and [_value] between "aria-label" and text content. The strategy for
/// TalkBack is to combine [_label] and [_value] into a single "aria-label".
///
/// The [_value] is not always rendered. Some semantics nodes correspond to
/// interactive controls, such as an `<input>` element. In such case the value
/// is reported via that element's `value` attribute rather than rendering it
/// separately.
///
/// Aria role image is not managed by this role manager. Img role and label
/// describes the visual are added in [ImageRoleManager].
class LabelAndValue extends RoleManager {
  LabelAndValue(SemanticsObject semanticsObject)
      : super(Role.labelAndValue, semanticsObject);

  /// Supplements the "aria-label" that renders the combination of [_label] and
  /// [_value] to semantics as text content.
  ///
  /// This extra element is needed for the following reasons:
  ///
  /// - VoiceOver on iOS Safari does not recognize standalone "aria-label". It
  ///   only works for specific roles.
  /// - TalkBack does support "aria-label". However, if an element has children
  ///   its label is not reachable via accessibility focus. This happens, for
  ///   example in popup dialogs, such as the alert dialog. The text of the
  ///   alert is supplied as a label on the parent node.
  html.Element? _auxiliaryValueElement;

  @override
  void update() {
    final bool hasValue = semanticsObject.hasValue;
    final bool hasLabel = semanticsObject.hasLabel;

    // If the node is incrementable or a text field the value is reported to the
    // browser via the respective role managers. We do not need to also render
    // it again here.
    final bool shouldDisplayValue = hasValue &&
        !semanticsObject.isIncrementable &&
        !semanticsObject.isTextField;

    if (!hasLabel && !shouldDisplayValue) {
      _cleanUpDom();
      return;
    }

    final StringBuffer combinedValue = StringBuffer();
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

    if (semanticsObject.hasFlag(ui.SemanticsFlag.isHeader)) {
      semanticsObject.setAriaRole('heading', true);
    }

    if (_auxiliaryValueElement == null) {
      _auxiliaryValueElement = html.Element.tag('flt-semantics-value');
      // Absolute positioning and sizing of leaf text elements confuses
      // VoiceOver. So we let the browser size the value node. The node will
      // still have a bigger tap area. However, if the node is a parent to other
      // nodes, then VoiceOver behaves as expected with absolute positioning and
      // sizing.
      if (semanticsObject.hasChildren) {
        _auxiliaryValueElement!.style
          ..position = 'absolute'
          ..top = '0'
          ..left = '0'
          ..width = '${semanticsObject.rect!.width}px'
          ..height = '${semanticsObject.rect!.height}px';
      }
      _auxiliaryValueElement!.style.fontSize = '6px';
      semanticsObject.element.append(_auxiliaryValueElement!);
    }
    _auxiliaryValueElement!.text = combinedValue.toString();
  }

  void _cleanUpDom() {
    if (_auxiliaryValueElement != null) {
      _auxiliaryValueElement!.remove();
      _auxiliaryValueElement = null;
    }
    semanticsObject.element.attributes.remove('aria-label');
    semanticsObject.setAriaRole('heading', false);
  }

  @override
  void dispose() {
    _cleanUpDom();
  }
}
