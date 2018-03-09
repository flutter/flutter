// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show Offset, Rect, SemanticsAction, SemanticsFlag,
       TextDirection;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show MatrixUtils, TransformProperty;
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

import 'semantics_event.dart';

export 'dart:ui' show SemanticsAction;
export 'semantics_event.dart';

/// Signature for a function that is called for each [SemanticsNode].
///
/// Return false to stop visiting nodes.
///
/// Used by [SemanticsNode.visitChildren].
typedef bool SemanticsNodeVisitor(SemanticsNode node);

/// Signature for [SemanticsAction]s that move the cursor.
///
/// If `extendSelection` is set to true the cursor movement should extend the
/// current selection or (if nothing is currently selected) start a selection.
typedef void MoveCursorHandler(bool extendSelection);

/// Signature for the [SemanticsAction.setSelection] handlers to change the
/// text selection (or re-position the cursor) to `selection`.
typedef void SetSelectionHandler(TextSelection selection);

typedef void _SemanticsActionHandler(dynamic args);

/// A tag for a [SemanticsNode].
///
/// Tags can be interpreted by the parent of a [SemanticsNode]
/// and depending on the presence of a tag the parent can for example decide
/// how to add the tagged node as a child. Tags are not sent to the engine.
///
/// As an example, the [RenderSemanticsGestureHandler] uses tags to determine
/// if a child node should be excluded from the scrollable area for semantic
/// purposes.
///
/// The provided [name] is only used for debugging. Two tags created with the
/// same [name] and the `new` operator are not considered identical. However,
/// two tags created with the same [name] and the `const` operator are always
/// identical.
class SemanticsTag {
  /// Creates a [SemanticsTag].
  ///
  /// The provided [name] is only used for debugging. Two tags created with the
  /// same [name] and the `new` operator are not considered identical. However,
  /// two tags created with the same [name] and the `const` operator are always
  /// identical.
  const SemanticsTag(this.name);

  /// A human-readable name for this tag used for debugging.
  ///
  /// This string is not used to determine if two tags are identical.
  final String name;

  @override
  String toString() => '$runtimeType($name)';
}

/// Summary information about a [SemanticsNode] object.
///
/// A semantics node might [SemanticsNode.mergeAllDescendantsIntoThisNode],
/// which means the individual fields on the semantics node don't fully describe
/// the semantics at that node. This data structure contains the full semantics
/// for the node.
///
/// Typically obtained from [SemanticsNode.getSemanticsData].
@immutable
class SemanticsData extends Diagnosticable {
  /// Creates a semantics data object.
  ///
  /// The [flags], [actions], [label], and [Rect] arguments must not be null.
  ///
  /// If [label] is not empty, then [textDirection] must also not be null.
  const SemanticsData({
    @required this.flags,
    @required this.actions,
    @required this.label,
    @required this.increasedValue,
    @required this.value,
    @required this.decreasedValue,
    @required this.hint,
    @required this.textDirection,
    @required this.nextNodeId,
    @required this.previousNodeId,
    @required this.rect,
    @required this.textSelection,
    @required this.scrollPosition,
    @required this.scrollExtentMax,
    @required this.scrollExtentMin,
    this.tags,
    this.transform,
  }) : assert(flags != null),
       assert(actions != null),
       assert(label != null),
       assert(value != null),
       assert(decreasedValue != null),
       assert(increasedValue != null),
       assert(hint != null),
       assert(label == '' || textDirection != null, 'A SemanticsData object with label "$label" had a null textDirection.'),
       assert(value == '' || textDirection != null, 'A SemanticsData object with value "$value" had a null textDirection.'),
       assert(hint == '' || textDirection != null, 'A SemanticsData object with hint "$hint" had a null textDirection.'),
       assert(decreasedValue == '' || textDirection != null, 'A SemanticsData object with decreasedValue "$decreasedValue" had a null textDirection.'),
       assert(increasedValue == '' || textDirection != null, 'A SemanticsData object with increasedValue "$increasedValue" had a null textDirection.'),
       assert(rect != null);

  /// A bit field of [SemanticsFlag]s that apply to this node.
  final int flags;

  /// A bit field of [SemanticsAction]s that apply to this node.
  final int actions;

  /// A textual description of this node.
  ///
  /// The reading direction is given by [textDirection].
  final String label;

  /// A textual description for the current value of the node.
  ///
  /// The reading direction is given by [textDirection].
  final String value;

  /// The value that [value] will become after performing a
  /// [SemanticsAction.increase] action.
  ///
  /// The reading direction is given by [textDirection].
  final String increasedValue;

  /// The value that [value] will become after performing a
  /// [SemanticsAction.decrease] action.
  ///
  /// The reading direction is given by [textDirection].
  final String decreasedValue;

  /// A brief description of the result of performing an action on this node.
  ///
  /// The reading direction is given by [textDirection].
  final String hint;

  /// The reading direction for the text in [label], [value], [hint],
  /// [increasedValue], and [decreasedValue].
  final TextDirection textDirection;

  /// The index indicating the ID of the next node in the traversal order after
  /// this node for the platform's accessibility services.
  final int nextNodeId;

  /// The index indicating the ID of the previous node in the traversal order before
  /// this node for the platform's accessibility services.
  final int previousNodeId;

  /// The currently selected text (or the position of the cursor) within [value]
  /// if this node represents a text field.
  final TextSelection textSelection;

  /// Indicates the current scrolling position in logical pixels if the node is
  /// scrollable.
  ///
  /// The properties [scrollExtentMin] and [scrollExtentMax] indicate the valid
  /// in-range values for this property. The value for [scrollPosition] may
  /// (temporarily) be outside that range, e.g. during an overscroll.
  ///
  /// See also:
  ///
  ///  * [ScrollPosition.pixels], from where this value is usually taken.
  final double scrollPosition;

  /// Indicates the maximum in-range value for [scrollPosition] if the node is
  /// scrollable.
  ///
  /// This value may be infinity if the scroll is unbound.
  ///
  /// See also:
  ///
  ///  * [ScrollPosition.maxScrollExtent], from where this value is usually taken.
  final double scrollExtentMax;

  /// Indicates the minimum in-range value for [scrollPosition] if the node is
  /// scrollable.
  ///
  /// This value may be infinity if the scroll is unbound.
  ///
  /// See also:
  ///
  ///  * [ScrollPosition.minScrollExtent], from where this value is usually taken.
  final double scrollExtentMin;

  /// The bounding box for this node in its coordinate system.
  final Rect rect;

  /// The set of [SemanticsTag]s associated with this node.
  final Set<SemanticsTag> tags;

  /// The transform from this node's coordinate system to its parent's coordinate system.
  ///
  /// By default, the transform is null, which represents the identity
  /// transformation (i.e., that this node has the same coordinate system as its
  /// parent).
  final Matrix4 transform;

  /// Whether [flags] contains the given flag.
  bool hasFlag(SemanticsFlag flag) => (flags & flag.index) != 0;

  /// Whether [actions] contains the given action.
  bool hasAction(SemanticsAction action) => (actions & action.index) != 0;

  @override
  String toStringShort() => '$runtimeType';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(new DiagnosticsProperty<Rect>('rect', rect, showName: false));
    properties.add(new TransformProperty('transform', transform, showName: false, defaultValue: null));
    final List<String> actionSummary = <String>[];
    for (SemanticsAction action in SemanticsAction.values.values) {
      if ((actions & action.index) != 0)
        actionSummary.add(describeEnum(action));
    }
    properties.add(new IterableProperty<String>('actions', actionSummary, ifEmpty: null));

    final List<String> flagSummary = <String>[];
    for (SemanticsFlag flag in SemanticsFlag.values.values) {
      if ((flags & flag.index) != 0)
        flagSummary.add(describeEnum(flag));
    }
    properties.add(new IterableProperty<String>('flags', flagSummary, ifEmpty: null));
    properties.add(new StringProperty('label', label, defaultValue: ''));
    properties.add(new StringProperty('value', value, defaultValue: ''));
    properties.add(new StringProperty('increasedValue', increasedValue, defaultValue: ''));
    properties.add(new StringProperty('decreasedValue', decreasedValue, defaultValue: ''));
    properties.add(new StringProperty('hint', hint, defaultValue: ''));
    properties.add(new EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(new IntProperty('nextNodeId', nextNodeId, defaultValue: null));
    properties.add(new IntProperty('previousNodeId', previousNodeId, defaultValue: null));
    if (textSelection?.isValid == true)
      properties.add(new MessageProperty('textSelection', '[${textSelection.start}, ${textSelection.end}]'));
    properties.add(new DoubleProperty('scrollExtentMin', scrollExtentMin, defaultValue: null));
    properties.add(new DoubleProperty('scrollPosition', scrollPosition, defaultValue: null));
    properties.add(new DoubleProperty('scrollExtentMax', scrollExtentMax, defaultValue: null));
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! SemanticsData)
      return false;
    final SemanticsData typedOther = other;
    return typedOther.flags == flags
        && typedOther.actions == actions
        && typedOther.label == label
        && typedOther.value == value
        && typedOther.increasedValue == increasedValue
        && typedOther.decreasedValue == decreasedValue
        && typedOther.hint == hint
        && typedOther.textDirection == textDirection
        && typedOther.nextNodeId == nextNodeId
        && typedOther.previousNodeId == previousNodeId
        && typedOther.rect == rect
        && setEquals(typedOther.tags, tags)
        && typedOther.textSelection == textSelection
        && typedOther.scrollPosition == scrollPosition
        && typedOther.scrollExtentMax == scrollExtentMax
        && typedOther.scrollExtentMin == scrollExtentMin
        && typedOther.transform == transform;
  }

  @override
  int get hashCode => ui.hashValues(flags, actions, label, value, increasedValue, decreasedValue, hint, textDirection, nextNodeId, previousNodeId, rect, tags, textSelection, scrollPosition, scrollExtentMax, scrollExtentMin, transform);
}

class _SemanticsDiagnosticableNode extends DiagnosticableNode<SemanticsNode> {
  _SemanticsDiagnosticableNode({
    String name,
    @required SemanticsNode value,
    @required DiagnosticsTreeStyle style,
    @required this.childOrder,
  }) : super(
    name: name,
    value: value,
    style: style,
  );

  final DebugSemanticsDumpOrder childOrder;

  @override
  List<DiagnosticsNode> getChildren() {
    if (value != null)
      return value.debugDescribeChildren(childOrder: childOrder);

    return const <DiagnosticsNode>[];
  }
}

/// Contains properties used by assistive technologies to make the application
/// more accessible.
///
/// The properties of this class are used to generate a [SemanticsNode]s in the
/// semantics tree.
@immutable
class SemanticsProperties extends DiagnosticableTree {
  /// Creates a semantic annotation.
  const SemanticsProperties({
    this.enabled,
    this.checked,
    this.selected,
    this.button,
    this.header,
    this.textField,
    this.focused,
    this.inMutuallyExclusiveGroup,
    this.label,
    this.value,
    this.increasedValue,
    this.decreasedValue,
    this.hint,
    this.textDirection,
    this.sortOrder,
    this.onTap,
    this.onLongPress,
    this.onScrollLeft,
    this.onScrollRight,
    this.onScrollUp,
    this.onScrollDown,
    this.onIncrease,
    this.onDecrease,
    this.onCopy,
    this.onCut,
    this.onPaste,
    this.onMoveCursorForwardByCharacter,
    this.onMoveCursorBackwardByCharacter,
    this.onSetSelection,
    this.onDidGainAccessibilityFocus,
    this.onDidLoseAccessibilityFocus,
  });

  /// If non-null, indicates that this subtree represents something that can be
  /// in an enabled or disabled state.
  ///
  /// For example, a button that a user can currently interact with would set
  /// this field to true. A button that currently does not respond to user
  /// interactions would set this field to false.
  final bool enabled;

  /// If non-null, indicates that this subtree represents a checkbox
  /// or similar widget with a "checked" state, and what its current
  /// state is.
  final bool checked;

  /// If non-null indicates that this subtree represents something that can be
  /// in a selected or unselected state, and what its current state is.
  ///
  /// The active tab in a tab bar for example is considered "selected", whereas
  /// all other tabs are unselected.
  final bool selected;

  /// If non-null, indicates that this subtree represents a button.
  ///
  /// TalkBack/VoiceOver provides users with the hint "button" when a button
  /// is focused.
  final bool button;

  /// If non-null, indicates that this subtree represents a header.
  ///
  /// A header divides into sections. For example, an address book application
  /// might define headers A, B, C, etc. to divide the list of alphabetically
  /// sorted contacts into sections.
  final bool header;

  /// If non-null, indicates that this subtree represents a text field.
  ///
  /// TalkBack/VoiceOver provide special affordances to enter text into a
  /// text field.
  final bool textField;

  /// If non-null, whether the node currently holds input focus.
  ///
  /// At most one node in the tree should hold input focus at any point in time.
  ///
  /// Input focus (indicates that the node will receive keyboard events) is not
  /// to be confused with accessibility focus. Accessibility focus is the
  /// green/black rectangular that TalkBack/VoiceOver on the screen and is
  /// separate from input focus.
  final bool focused;

  /// If non-null, whether a semantic node is in a mutually exclusive group.
  ///
  /// For example, a radio button is in a mutually exclusive group because only
  /// one radio button in that group can be marked as [checked].
  final bool inMutuallyExclusiveGroup;

  /// Provides a textual description of the widget.
  ///
  /// If a label is provided, there must either by an ambient [Directionality]
  /// or an explicit [textDirection] should be provided.
  ///
  /// See also:
  ///
  ///  * [SemanticsConfiguration.label] for a description of how this is exposed
  ///    in TalkBack and VoiceOver.
  final String label;

  /// Provides a textual description of the value of the widget.
  ///
  /// If a value is provided, there must either by an ambient [Directionality]
  /// or an explicit [textDirection] should be provided.
  ///
  /// See also:
  ///
  ///  * [SemanticsConfiguration.value] for a description of how this is exposed
  ///    in TalkBack and VoiceOver.
  final String value;

  /// The value that [value] will become after a [SemanticsAction.increase]
  /// action has been performed on this widget.
  ///
  /// If a value is provided, [onIncrease] must also be set and there must
  /// either be an ambient [Directionality] or an explicit [textDirection]
  /// must be provided.
  ///
  /// See also:
  ///
  ///  * [SemanticsConfiguration.increasedValue] for a description of how this
  ///    is exposed in TalkBack and VoiceOver.
  final String increasedValue;

  /// The value that [value] will become after a [SemanticsAction.decrease]
  /// action has been performed on this widget.
  ///
  /// If a value is provided, [onDecrease] must also be set and there must
  /// either be an ambient [Directionality] or an explicit [textDirection]
  /// must be provided.
  ///
  /// See also:
  ///
  ///  * [SemanticsConfiguration.decreasedValue] for a description of how this
  ///    is exposed in TalkBack and VoiceOver.
  final String decreasedValue;

  /// Provides a brief textual description of the result of an action performed
  /// on the widget.
  ///
  /// If a hint is provided, there must either be an ambient [Directionality]
  /// or an explicit [textDirection] should be provided.
  ///
  /// See also:
  ///
  ///  * [SemanticsConfiguration.hint] for a description of how this is exposed
  ///    in TalkBack and VoiceOver.
  final String hint;

  /// The reading direction of the [label], [value], [hint], [increasedValue],
  /// and [decreasedValue].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection textDirection;

  /// Provides a traversal sorting order for this [Semantics] node.
  ///
  /// This is used to describe the order in which the semantic node should be
  /// traversed by the accessibility services on the platform (e.g. VoiceOver
  /// on iOS and TalkBack on Android).
  ///
  /// If [sortOrder.discardParentOrder] is false (the default), [sortOrder]'s
  /// sort keys are appended to the list of keys from any ancestor nodes into a
  /// list of [SemanticsSortKey]s that are compared in pairwise order.
  /// Otherwise, it ignores the ancestor's [sortOrder] on this node.
  ///
  /// See also:
  ///
  ///  * [SemanticsSortOrder] which provides a way to specify the order in
  ///    which semantic nodes are sorted.
  final SemanticsSortOrder sortOrder;

  /// The handler for [SemanticsAction.tap].
  ///
  /// This is the semantic equivalent of a user briefly tapping the screen with
  /// the finger without moving it. For example, a button should implement this
  /// action.
  ///
  /// VoiceOver users on iOS and TalkBack users on Android can trigger this
  /// action by double-tapping the screen while an element is focused.
  final VoidCallback onTap;

  /// The handler for [SemanticsAction.longPress].
  ///
  /// This is the semantic equivalent of a user pressing and holding the screen
  /// with the finger for a few seconds without moving it.
  ///
  /// VoiceOver users on iOS and TalkBack users on Android can trigger this
  /// action by double-tapping the screen without lifting the finger after the
  /// second tap.
  final VoidCallback onLongPress;

  /// The handler for [SemanticsAction.scrollLeft].
  ///
  /// This is the semantic equivalent of a user moving their finger across the
  /// screen from right to left. It should be recognized by controls that are
  /// horizontally scrollable.
  ///
  /// VoiceOver users on iOS can trigger this action by swiping left with three
  /// fingers. TalkBack users on Android can trigger this action by swiping
  /// right and then left in one motion path. On Android, [onScrollUp] and
  /// [onScrollLeft] share the same gesture. Therefore, only on of them should
  /// be provided.
  final VoidCallback onScrollLeft;

  /// The handler for [SemanticsAction.scrollRight].
  ///
  /// This is the semantic equivalent of a user moving their finger across the
  /// screen from left to right. It should be recognized by controls that are
  /// horizontally scrollable.
  ///
  /// VoiceOver users on iOS can trigger this action by swiping right with three
  /// fingers. TalkBack users on Android can trigger this action by swiping
  /// left and then right in one motion path. On Android, [onScrollDown] and
  /// [onScrollRight] share the same gesture. Therefore, only on of them should
  /// be provided.
  final VoidCallback onScrollRight;

  /// The handler for [SemanticsAction.scrollUp].
  ///
  /// This is the semantic equivalent of a user moving their finger across the
  /// screen from bottom to top. It should be recognized by controls that are
  /// vertically scrollable.
  ///
  /// VoiceOver users on iOS can trigger this action by swiping up with three
  /// fingers. TalkBack users on Android can trigger this action by swiping
  /// right and then left in one motion path. On Android, [onScrollUp] and
  /// [onScrollLeft] share the same gesture. Therefore, only on of them should
  /// be provided.
  final VoidCallback onScrollUp;

  /// The handler for [SemanticsAction.scrollDown].
  ///
  /// This is the semantic equivalent of a user moving their finger across the
  /// screen from top to bottom. It should be recognized by controls that are
  /// vertically scrollable.
  ///
  /// VoiceOver users on iOS can trigger this action by swiping down with three
  /// fingers. TalkBack users on Android can trigger this action by swiping
  /// left and then right in one motion path. On Android, [onScrollDown] and
  /// [onScrollRight] share the same gesture. Therefore, only on of them should
  /// be provided.
  final VoidCallback onScrollDown;

  /// The handler for [SemanticsAction.increase].
  ///
  /// This is a request to increase the value represented by the widget. For
  /// example, this action might be recognized by a slider control.
  ///
  /// If a [value] is set, [increasedValue] must also be provided and
  /// [onIncrease] must ensure that [value] will be set to [increasedValue].
  ///
  /// VoiceOver users on iOS can trigger this action by swiping up with one
  /// finger. TalkBack users on Android can trigger this action by pressing the
  /// volume up button.
  final VoidCallback onIncrease;

  /// The handler for [SemanticsAction.decrease].
  ///
  /// This is a request to decrease the value represented by the widget. For
  /// example, this action might be recognized by a slider control.
  ///
  /// If a [value] is set, [decreasedValue] must also be provided and
  /// [onDecrease] must ensure that [value] will be set to [decreasedValue].
  ///
  /// VoiceOver users on iOS can trigger this action by swiping down with one
  /// finger. TalkBack users on Android can trigger this action by pressing the
  /// volume down button.
  final VoidCallback onDecrease;

  /// The handler for [SemanticsAction.copy].
  ///
  /// This is a request to copy the current selection to the clipboard.
  ///
  /// TalkBack users on Android can trigger this action from the local context
  /// menu of a text field, for example.
  final VoidCallback onCopy;

  /// The handler for [SemanticsAction.cut].
  ///
  /// This is a request to cut the current selection and place it in the
  /// clipboard.
  ///
  /// TalkBack users on Android can trigger this action from the local context
  /// menu of a text field, for example.
  final VoidCallback onCut;

  /// The handler for [SemanticsAction.paste].
  ///
  /// This is a request to paste the current content of the clipboard.
  ///
  /// TalkBack users on Android can trigger this action from the local context
  /// menu of a text field, for example.
  final VoidCallback onPaste;

  /// The handler for [SemanticsAction.onMoveCursorForwardByCharacter].
  ///
  /// This handler is invoked when the user wants to move the cursor in a
  /// text field forward by one character.
  ///
  /// TalkBack users can trigger this by pressing the volume up key while the
  /// input focus is in a text field.
  final MoveCursorHandler onMoveCursorForwardByCharacter;

  /// The handler for [SemanticsAction.onMoveCursorBackwardByCharacter].
  ///
  /// This handler is invoked when the user wants to move the cursor in a
  /// text field backward by one character.
  ///
  /// TalkBack users can trigger this by pressing the volume down key while the
  /// input focus is in a text field.
  final MoveCursorHandler onMoveCursorBackwardByCharacter;

  /// The handler for [SemanticsAction.setSelection].
  ///
  /// This handler is invoked when the user either wants to change the currently
  /// selected text in a text field or change the position of the cursor.
  ///
  /// TalkBack users can trigger this handler by selecting "Move cursor to
  /// beginning/end" or "Select all" from the local context menu.
  final SetSelectionHandler onSetSelection;

  /// The handler for [SemanticsAction.didGainAccessibilityFocus].
  ///
  /// This handler is invoked when the node annotated with this handler gains
  /// the accessibility focus. The accessibility focus is the
  /// green (on Android with TalkBack) or black (on iOS with VoiceOver)
  /// rectangle shown on screen to indicate what element an accessibility
  /// user is currently interacting with.
  ///
  /// The accessibility focus is different from the input focus. The input focus
  /// is usually held by the element that currently responds to keyboard inputs.
  /// Accessibility focus and input focus can be held by two different nodes!
  ///
  /// See also:
  ///
  ///  * [onDidLoseAccessibilityFocus], which is invoked when the accessibility
  ///    focus is removed from the node
  ///  * [FocusNode], [FocusScope], [FocusManager], which manage the input focus
  final VoidCallback onDidGainAccessibilityFocus;

  /// The handler for [SemanticsAction.didLoseAccessibilityFocus].
  ///
  /// This handler is invoked when the node annotated with this handler
  /// loses the accessibility focus. The accessibility focus is
  /// the green (on Android with TalkBack) or black (on iOS with VoiceOver)
  /// rectangle shown on screen to indicate what element an accessibility
  /// user is currently interacting with.
  ///
  /// The accessibility focus is different from the input focus. The input focus
  /// is usually held by the element that currently responds to keyboard inputs.
  /// Accessibility focus and input focus can be held by two different nodes!
  ///
  /// See also:
  ///
  ///  * [onDidGainAccessibilityFocus], which is invoked when the node gains
  ///    accessibility focus
  ///  * [FocusNode], [FocusScope], [FocusManager], which manage the input focus
  final VoidCallback onDidLoseAccessibilityFocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DiagnosticsProperty<bool>('checked', checked, defaultValue: null));
    description.add(new DiagnosticsProperty<bool>('selected', selected, defaultValue: null));
    description.add(new StringProperty('label', label, defaultValue: ''));
    description.add(new StringProperty('value', value));
    description.add(new StringProperty('hint', hint));
    description.add(new EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    description.add(new DiagnosticsProperty<SemanticsSortOrder>('sortOrder', sortOrder, defaultValue: null));
  }
}

/// In tests use this function to reset the counter used to generate
/// [SemanticsNode.id].
void debugResetSemanticsIdCounter() {
  SemanticsNode._lastIdentifier = 0;
}

/// A node that represents some semantic data.
///
/// The semantics tree is maintained during the semantics phase of the pipeline
/// (i.e., during [PipelineOwner.flushSemantics]), which happens after
/// compositing. The semantics tree is then uploaded into the engine for use
/// by assistive technology.
class SemanticsNode extends AbstractNode with DiagnosticableTreeMixin {
  /// Creates a semantic node.
  ///
  /// Each semantic node has a unique identifier that is assigned when the node
  /// is created.
  SemanticsNode({
    this.key,
    VoidCallback showOnScreen,
  }) : id = _generateNewId(),
       _showOnScreen = showOnScreen;

  /// Creates a semantic node to represent the root of the semantics tree.
  ///
  /// The root node is assigned an identifier of zero.
  SemanticsNode.root({
    this.key,
    VoidCallback showOnScreen,
    SemanticsOwner owner,
  }) : id = 0,
       _showOnScreen = showOnScreen {
    attach(owner);
  }

  static int _lastIdentifier = 0;
  static int _generateNewId() {
    _lastIdentifier += 1;
    return _lastIdentifier;
  }

  /// Uniquely identifies this node in the list of sibling nodes.
  ///
  /// Keys are used during the construction of the semantics tree. They are not
  /// transferred to the engine.
  final Key key;

  /// The unique identifier for this node.
  ///
  /// The root node has an id of zero. Other nodes are given a unique id when
  /// they are created.
  final int id;

  final VoidCallback _showOnScreen;

  // GEOMETRY

  /// The transform from this node's coordinate system to its parent's coordinate system.
  ///
  /// By default, the transform is null, which represents the identity
  /// transformation (i.e., that this node has the same coordinate system as its
  /// parent).
  Matrix4 get transform => _transform;
  Matrix4 _transform;
  set transform(Matrix4 value) {
    if (!MatrixUtils.matrixEquals(_transform, value)) {
      _transform = MatrixUtils.isIdentity(value) ? null : value;
      _markDirty();
    }
  }

  /// The bounding box for this node in its coordinate system.
  Rect get rect => _rect;
  Rect _rect = Rect.zero;
  set rect(Rect value) {
    assert(value != null);
    if (_rect != value) {
      _rect = value;
      _markDirty();
    }
  }

  /// The clip rect from an ancestor that was applied to this node.
  ///
  /// Expressed in the coordinate system of the node. May be null if no clip has
  /// been applied.
  Rect parentClipRect;

  /// Whether the node is invisible.
  ///
  /// A node whose [rect] is outside of the bounds of the screen and hence not
  /// reachable for users is considered invisible if its semantic information
  /// is not merged into a (partially) visible parent as indicated by
  /// [isMergedIntoParent].
  ///
  /// An invisible node can be safely dropped from the semantic tree without
  /// loosing semantic information that is relevant for describing the content
  /// currently shown on screen.
  bool get isInvisible => !isMergedIntoParent && rect.isEmpty;

  // MERGING

  /// Whether this node merges its semantic information into an ancestor node.
  bool get isMergedIntoParent => _isMergedIntoParent;
  bool _isMergedIntoParent = false;
  set isMergedIntoParent(bool value) {
    assert(value != null);
    if (_isMergedIntoParent == value)
      return;
    _isMergedIntoParent = value;
    _markDirty();
  }

  /// Whether this node is taking part in a merge of semantic information.
  ///
  /// This returns true if the node is either merged into an ancestor node or if
  /// decedent nodes are merged into this node.
  ///
  /// See also:
  ///
  ///  * [isMergedIntoParent]
  ///  * [mergeAllDescendantsIntoThisNode]
  bool get isPartOfNodeMerging => mergeAllDescendantsIntoThisNode || isMergedIntoParent;

  /// Whether this node and all of its descendants should be treated as one logical entity.
  bool get mergeAllDescendantsIntoThisNode => _mergeAllDescendantsIntoThisNode;
  bool _mergeAllDescendantsIntoThisNode = _kEmptyConfig.isMergingSemanticsOfDescendants;


  // CHILDREN

  /// Contains the children in inverse hit test order (i.e. paint order).
  List<SemanticsNode> _children;

  /// A snapshot of `newChildren` passed to [_replaceChildren] that we keep in
  /// debug mode. It supports the assertion that user does not mutate the list
  /// of children.
  List<SemanticsNode> _debugPreviousSnapshot;

  void _replaceChildren(List<SemanticsNode> newChildren) {
    assert(!newChildren.any((SemanticsNode child) => child == this));
    assert(() {
      if (identical(newChildren, _children)) {
        final StringBuffer mutationErrors = new StringBuffer();
        if (newChildren.length != _debugPreviousSnapshot.length) {
          mutationErrors.writeln(
            'The list\'s length has changed from ${_debugPreviousSnapshot.length} '
            'to ${newChildren.length}.'
          );
        } else {
          for (int i = 0; i < newChildren.length; i++) {
            if (!identical(newChildren[i], _debugPreviousSnapshot[i])) {
              mutationErrors.writeln(
                'Child node at position $i was replaced:\n'
                'Previous child: ${newChildren[i]}\n'
                'New child: ${_debugPreviousSnapshot[i]}\n'
              );
            }
          }
        }
        if (mutationErrors.isNotEmpty) {
          throw new FlutterError(
            'Failed to replace child semantics nodes because the list of `SemanticsNode`s was mutated.\n'
            'Instead of mutating the existing list, create a new list containing the desired `SemanticsNode`s.\n'
            'Error details:\n'
            '$mutationErrors'
          );
        }
      }
      assert(!newChildren.any((SemanticsNode node) => node.isMergedIntoParent) || isPartOfNodeMerging);

      _debugPreviousSnapshot = new List<SemanticsNode>.from(newChildren);

      SemanticsNode ancestor = this;
      while (ancestor.parent is SemanticsNode)
        ancestor = ancestor.parent;
      assert(!newChildren.any((SemanticsNode child) => child == ancestor));
      return true;
    }());
    assert(() {
      final Set<SemanticsNode> seenChildren = new Set<SemanticsNode>();
      for (SemanticsNode child in newChildren)
        assert(seenChildren.add(child)); // check for duplicate adds
      return true;
    }());

    // The goal of this function is updating sawChange.
    if (_children != null) {
      for (SemanticsNode child in _children)
        child._dead = true;
    }
    if (newChildren != null) {
      for (SemanticsNode child in newChildren) {
        assert(!child.isInvisible, 'Child $child is invisible and should not be added as a child of $this.');
        child._dead = false;
      }
    }
    bool sawChange = false;
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (child._dead) {
          if (child.parent == this) {
            // we might have already had our child stolen from us by
            // another node that is deeper in the tree.
            dropChild(child);
          }
          sawChange = true;
        }
      }
    }
    if (newChildren != null) {
      for (SemanticsNode child in newChildren) {
        if (child.parent != this) {
          if (child.parent != null) {
            // we're rebuilding the tree from the bottom up, so it's possible
            // that our child was, in the last pass, a child of one of our
            // ancestors. In that case, we drop the child eagerly here.
            // TODO(ianh): Find a way to assert that the same node didn't
            // actually appear in the tree in two places.
            child.parent?.dropChild(child);
          }
          assert(!child.attached);
          adoptChild(child);
          sawChange = true;
        }
      }
    }
    if (!sawChange && _children != null) {
      assert(newChildren != null);
      assert(newChildren.length == _children.length);
      // Did the order change?
      for (int i = 0; i < _children.length; i++) {
        if (_children[i].id != newChildren[i].id) {
          sawChange = true;
          break;
        }
      }
    }
    _children = newChildren;
    if (sawChange)
      _markDirty();
  }

  /// Whether this node has a non-zero number of children.
  bool get hasChildren => _children?.isNotEmpty ?? false;
  bool _dead = false;

  /// The number of children this node has.
  int get childrenCount => hasChildren ? _children.length : 0;

  /// Visits the immediate children of this node.
  ///
  /// This function calls visitor for each child in a pre-order traversal
  /// until visitor returns false. Returns true if all the visitor calls
  /// returned true, otherwise returns false.
  void visitChildren(SemanticsNodeVisitor visitor) {
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (!visitor(child))
          return;
      }
    }
  }

  /// Visit all the descendants of this node.
  ///
  /// This function calls visitor for each descendant in a pre-order traversal
  /// until visitor returns false. Returns true if all the visitor calls
  /// returned true, otherwise returns false.
  bool _visitDescendants(SemanticsNodeVisitor visitor) {
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (!visitor(child) || !child._visitDescendants(visitor))
          return false;
      }
    }
    return true;
  }

  // AbstractNode OVERRIDES

  @override
  SemanticsOwner get owner => super.owner;

  @override
  SemanticsNode get parent => super.parent;

  @override
  void redepthChildren() {
    _children?.forEach(redepthChild);
  }

  @override
  void attach(SemanticsOwner owner) {
    super.attach(owner);
    assert(!owner._nodes.containsKey(id));
    owner._nodes[id] = this;
    owner._detachedNodes.remove(this);
    if (_dirty) {
      _dirty = false;
      _markDirty();
    }
    if (_children != null) {
      for (SemanticsNode child in _children)
        child.attach(owner);
    }
  }

  @override
  void detach() {
    assert(owner._nodes.containsKey(id));
    assert(!owner._detachedNodes.contains(this));
    owner._nodes.remove(id);
    owner._detachedNodes.add(this);
    super.detach();
    assert(owner == null);
    if (_children != null) {
      for (SemanticsNode child in _children) {
        // The list of children may be stale and may contain nodes that have
        // been assigned to a different parent.
        if (child.parent == this)
          child.detach();
      }
    }
    // The other side will have forgotten this node if we ever send
    // it again, so make sure to mark it dirty so that it'll get
    // sent if it is resurrected.
    _markDirty();
  }

  // DIRTY MANAGEMENT

  bool _dirty = false;
  void _markDirty() {
    if (_dirty)
      return;
    _dirty = true;
    if (attached) {
      assert(!owner._detachedNodes.contains(this));
      owner._dirtyNodes.add(this);
    }
  }

  bool _isDifferentFromCurrentSemanticAnnotation(SemanticsConfiguration config) {
    return _label != config.label ||
        _hint != config.hint ||
        _decreasedValue != config.decreasedValue ||
        _value != config.value ||
        _increasedValue != config.increasedValue ||
        _flags != config._flags ||
        _textDirection != config.textDirection ||
        _sortOrder != config._sortOrder ||
        _textSelection != config._textSelection ||
        _scrollPosition != config._scrollPosition ||
        _scrollExtentMax != config._scrollExtentMax ||
        _scrollExtentMin != config._scrollExtentMin ||
        _actionsAsBits != config._actionsAsBits ||
        _mergeAllDescendantsIntoThisNode != config.isMergingSemanticsOfDescendants;
  }

  // TAGS, LABELS, ACTIONS

  Map<SemanticsAction, _SemanticsActionHandler> _actions = _kEmptyConfig._actions;

  int _actionsAsBits = _kEmptyConfig._actionsAsBits;

  /// The [SemanticsTag]s this node is tagged with.
  ///
  /// Tags are used during the construction of the semantics tree. They are not
  /// transferred to the engine.
  Set<SemanticsTag> tags;

  /// Whether this node is tagged with `tag`.
  bool isTagged(SemanticsTag tag) => tags != null && tags.contains(tag);

  int _flags = _kEmptyConfig._flags;

  bool _hasFlag(SemanticsFlag flag) => _flags & flag.index != 0;

  /// A textual description of this node.
  ///
  /// The reading direction is given by [textDirection].
  String get label => _label;
  String _label = _kEmptyConfig.label;

  /// A textual description for the current value of the node.
  ///
  /// The reading direction is given by [textDirection].
  String get value => _value;
  String _value = _kEmptyConfig.value;

  /// The value that [value] will have after a [SemanticsAction.decrease] action
  /// has been performed.
  ///
  /// This property is only valid if the [SemanticsAction.decrease] action is
  /// available on this node.
  ///
  /// The reading direction is given by [textDirection].
  String get decreasedValue => _decreasedValue;
  String _decreasedValue = _kEmptyConfig.decreasedValue;

  /// The value that [value] will have after a [SemanticsAction.increase] action
  /// has been performed.
  ///
  /// This property is only valid if the [SemanticsAction.increase] action is
  /// available on this node.
  ///
  /// The reading direction is given by [textDirection].
  String get increasedValue => _increasedValue;
  String _increasedValue = _kEmptyConfig.increasedValue;

  /// A brief description of the result of performing an action on this node.
  ///
  /// The reading direction is given by [textDirection].
  String get hint => _hint;
  String _hint = _kEmptyConfig.hint;

  /// The reading direction for [label], [value], [hint], [increasedValue], and
  /// [decreasedValue].
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection = _kEmptyConfig.textDirection;

  /// The sort order for ordering the traversal of [SemanticsNode]s by the
  /// platform's accessibility services (e.g. VoiceOver on iOS and TalkBack on
  /// Android). This is used to determine the [nextNodeId] and [previousNodeId]
  /// during a semantics update.
  SemanticsSortOrder get sortOrder => _sortOrder;
  SemanticsSortOrder _sortOrder;

  /// The ID of the next node in the traversal order after this node.
  ///
  /// Only valid after at least one semantics update has been built.
  ///
  /// This is the value passed to the engine to tell it what the order
  /// should be for traversing semantics nodes.
  ///
  /// If this is set to -1, it will indicate that there is no next node to
  /// the engine (i.e. this is the last node in the sort order). When it is
  /// null, it means that no semantics update has been built yet.
  int get nextNodeId => _nextNodeId;
  int _nextNodeId;
  void _updateNextNodeId(int value) {
    if (value == _nextNodeId)
      return;
    _nextNodeId = value;
    _markDirty();
  }

  /// The ID of the previous node in the traversal order before this node.
  ///
  /// Only valid after at least one semantics update has been built.
  ///
  /// This is the value passed to the engine to tell it what the order
  /// should be for traversing semantics nodes.
  ///
  /// If this is set to -1, it will indicate that there is no previous node to
  /// the engine (i.e. this is the first node in the sort order). When it is
  /// null, it means that no semantics update has been built yet.
  int get previousNodeId => _previousNodeId;
  int _previousNodeId;
  void _updatePreviousNodeId(int value) {
    if (value == _previousNodeId)
      return;
    _previousNodeId = value;
    _markDirty();
  }

  /// The currently selected text (or the position of the cursor) within [value]
  /// if this node represents a text field.
  TextSelection get textSelection => _textSelection;
  TextSelection _textSelection;

  /// Indicates the current scrolling position in logical pixels if the node is
  /// scrollable.
  ///
  /// The properties [scrollExtentMin] and [scrollExtentMax] indicate the valid
  /// in-range values for this property. The value for [scrollPosition] may
  /// (temporarily) be outside that range, e.g. during an overscroll.
  ///
  /// See also:
  ///
  ///  * [ScrollPosition.pixels], from where this value is usually taken.
  double get scrollPosition => _scrollPosition;
  double _scrollPosition;


  /// Indicates the maximum in-range value for [scrollPosition] if the node is
  /// scrollable.
  ///
  /// This value may be infinity if the scroll is unbound.
  ///
  /// See also:
  ///
  ///  * [ScrollPosition.maxScrollExtent], from where this value is usually taken.
  double get scrollExtentMax => _scrollExtentMax;
  double _scrollExtentMax;

  /// Indicates the minimum in-range value for [scrollPosition] if the node is
  /// scrollable.
  ///
  /// This value may be infinity if the scroll is unbound.
  ///
  /// See also:
  ///
  ///  * [ScrollPosition.minScrollExtent] from where this value is usually taken.
  double get scrollExtentMin => _scrollExtentMin;
  double _scrollExtentMin;

  bool _canPerformAction(SemanticsAction action) => _actions.containsKey(action);

  static final SemanticsConfiguration _kEmptyConfig = new SemanticsConfiguration();

  /// Reconfigures the properties of this object to describe the configuration
  /// provided in the `config` argument and the children listed in the
  /// `childrenInInversePaintOrder` argument.
  ///
  /// The arguments may be null; this represents an empty configuration (all
  /// values at their defaults, no children).
  ///
  /// No reference is kept to the [SemanticsConfiguration] object, but the child
  /// list is used as-is and should therefore not be changed after this call.
  void updateWith({
    @required SemanticsConfiguration config,
    List<SemanticsNode> childrenInInversePaintOrder,
  }) {
    config ??= _kEmptyConfig;
    if (_isDifferentFromCurrentSemanticAnnotation(config))
      _markDirty();

    _label = config.label;
    _decreasedValue = config.decreasedValue;
    _value = config.value;
    _increasedValue = config.increasedValue;
    _hint = config.hint;
    _flags = config._flags;
    _textDirection = config.textDirection;
    _sortOrder = config.sortOrder;
    _actions = new Map<SemanticsAction, _SemanticsActionHandler>.from(config._actions);
    _actionsAsBits = config._actionsAsBits;
    _textSelection = config._textSelection;
    _scrollPosition = config._scrollPosition;
    _scrollExtentMax = config._scrollExtentMax;
    _scrollExtentMin = config._scrollExtentMin;
    _mergeAllDescendantsIntoThisNode = config.isMergingSemanticsOfDescendants;
    _replaceChildren(childrenInInversePaintOrder ?? const <SemanticsNode>[]);

    assert(
      !_canPerformAction(SemanticsAction.increase) || (_value == '') == (_increasedValue == ''),
      'A SemanticsNode with action "increase" needs to be annotated with either both "value" and "increasedValue" or neither',
    );
    assert(
      !_canPerformAction(SemanticsAction.decrease) || (_value == '') == (_decreasedValue == ''),
      'A SemanticsNode with action "increase" needs to be annotated with either both "value" and "decreasedValue" or neither',
    );
  }


  /// Returns a summary of the semantics for this node.
  ///
  /// If this node has [mergeAllDescendantsIntoThisNode], then the returned data
  /// includes the information from this node's descendants. Otherwise, the
  /// returned data matches the data on this node.
  SemanticsData getSemanticsData() {
    int flags = _flags;
    int actions = _actionsAsBits;
    String label = _label;
    String hint = _hint;
    String value = _value;
    String increasedValue = _increasedValue;
    String decreasedValue = _decreasedValue;
    TextDirection textDirection = _textDirection;
    int nextNodeId = _nextNodeId;
    int previousNodeId = _previousNodeId;
    Set<SemanticsTag> mergedTags = tags == null ? null : new Set<SemanticsTag>.from(tags);
    TextSelection textSelection = _textSelection;
    double scrollPosition = _scrollPosition;
    double scrollExtentMax = _scrollExtentMax;
    double scrollExtentMin = _scrollExtentMin;

    if (mergeAllDescendantsIntoThisNode) {
      _visitDescendants((SemanticsNode node) {
        assert(node.isMergedIntoParent);
        flags |= node._flags;
        actions |= node._actionsAsBits;
        textDirection ??= node._textDirection;
        nextNodeId ??= node._nextNodeId;
        previousNodeId ??= node._previousNodeId;
        textSelection ??= node._textSelection;
        scrollPosition ??= node._scrollPosition;
        scrollExtentMax ??= node._scrollExtentMax;
        scrollExtentMin ??= node._scrollExtentMin;
        if (value == '' || value == null)
          value = node._value;
        if (increasedValue == '' || increasedValue == null)
          increasedValue = node._increasedValue;
        if (decreasedValue == '' || decreasedValue == null)
          decreasedValue = node._decreasedValue;
        if (node.tags != null) {
          mergedTags ??= new Set<SemanticsTag>();
          mergedTags.addAll(node.tags);
        }
        label = _concatStrings(
          thisString: label,
          thisTextDirection: textDirection,
          otherString: node._label,
          otherTextDirection: node._textDirection,
        );
        hint = _concatStrings(
          thisString: hint,
          thisTextDirection: textDirection,
          otherString: node._hint,
          otherTextDirection: node._textDirection,
        );
        return true;
      });
    }

    return new SemanticsData(
      flags: flags,
      actions: actions,
      label: label,
      value: value,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      hint: hint,
      textDirection: textDirection,
      nextNodeId: nextNodeId,
      previousNodeId: previousNodeId,
      rect: rect,
      transform: transform,
      tags: mergedTags,
      textSelection: textSelection,
      scrollPosition: scrollPosition,
      scrollExtentMax: scrollExtentMax,
      scrollExtentMin: scrollExtentMin,
    );
  }

  static Float64List _initIdentityTransform() {
    return new Matrix4.identity().storage;
  }

  static final Int32List _kEmptyChildList = new Int32List(0);
  static final Float64List _kIdentityTransform = _initIdentityTransform();

  void _addToUpdate(ui.SemanticsUpdateBuilder builder) {
    assert(_dirty);
    final SemanticsData data = getSemanticsData();
    Int32List children;
    if (!hasChildren || mergeAllDescendantsIntoThisNode) {
      children = _kEmptyChildList;
    } else {
      final int childCount = _children.length;
      children = new Int32List(childCount);
      for (int i = 0; i < childCount; ++i) {
        children[i] = _children[i].id;
      }
    }
    builder.updateNode(
      id: id,
      flags: data.flags,
      actions: data.actions,
      rect: data.rect,
      label: data.label,
      value: data.value,
      decreasedValue: data.decreasedValue,
      increasedValue: data.increasedValue,
      hint: data.hint,
      textDirection: data.textDirection,
      nextNodeId: data.nextNodeId,
      previousNodeId: data.previousNodeId,
      textSelectionBase: data.textSelection != null ? data.textSelection.baseOffset : -1,
      textSelectionExtent: data.textSelection != null ? data.textSelection.extentOffset : -1,
      scrollPosition: data.scrollPosition != null ? data.scrollPosition : double.nan,
      scrollExtentMax: data.scrollExtentMax != null ? data.scrollExtentMax : double.nan,
      scrollExtentMin: data.scrollExtentMin != null ? data.scrollExtentMin : double.nan,
      transform: data.transform?.storage ?? _kIdentityTransform,
      children: children,
    );
    _dirty = false;
  }

  /// Sends a [SemanticsEvent] associated with this [SemanticsNode].
  ///
  /// Semantics events should be sent to inform interested parties (like
  /// the accessibility system of the operating system) about changes to the UI.
  ///
  /// For example, if this semantics node represents a scrollable list, a
  /// [ScrollCompletedSemanticsEvent] should be sent after a scroll action is completed.
  /// That way, the operating system can give additional feedback to the user
  /// about the state of the UI (e.g. on Android a ping sound is played to
  /// indicate a successful scroll in accessibility mode).
  void sendEvent(SemanticsEvent event) {
    if (!attached)
      return;
    SystemChannels.accessibility.send(event.toMap(nodeId: id));
  }

  @override
  String toStringShort() => '$runtimeType#$id';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    bool hideOwner = true;
    if (_dirty) {
      final bool inDirtyNodes = owner != null && owner._dirtyNodes.contains(this);
      properties.add(new FlagProperty('inDirtyNodes', value: inDirtyNodes, ifTrue: 'dirty', ifFalse: 'STALE'));
      hideOwner = inDirtyNodes;
    }
    properties.add(new DiagnosticsProperty<SemanticsOwner>('owner', owner, level: hideOwner ? DiagnosticLevel.hidden : DiagnosticLevel.info));
    properties.add(new FlagProperty('isMergedIntoParent', value: isMergedIntoParent, ifTrue: 'merged up ⬆️'));
    properties.add(new FlagProperty('mergeAllDescendantsIntoThisNode', value: mergeAllDescendantsIntoThisNode, ifTrue: 'merge boundary ⛔️'));
    final Offset offset = transform != null ? MatrixUtils.getAsTranslation(transform) : null;
    if (offset != null) {
      properties.add(new DiagnosticsProperty<Rect>('rect', rect.shift(offset), showName: false));
    } else {
      final double scale = transform != null ? MatrixUtils.getAsScale(transform) : null;
      String description;
      if (scale != null) {
        description = '$rect scaled by ${scale.toStringAsFixed(1)}x';
      } else if (transform != null && !MatrixUtils.isIdentity(transform)) {
        final String matrix = transform.toString().split('\n').take(4).map((String line) => line.substring(4)).join('; ');
        description = '$rect with transform [$matrix]';
      }
      properties.add(new DiagnosticsProperty<Rect>('rect', rect, description: description, showName: false));
    }
    final List<String> actions = _actions.keys.map((SemanticsAction action) => describeEnum(action)).toList()..sort();
    properties.add(new IterableProperty<String>('actions', actions, ifEmpty: null));
    final List<String> flags = SemanticsFlag.values.values.where((SemanticsFlag flag) => _hasFlag(flag)).map((SemanticsFlag flag) => flag.toString().substring('SemanticsFlag.'.length)).toList();
    properties.add(new IterableProperty<String>('flags', flags, ifEmpty: null));
    properties.add(new FlagProperty('isInvisible', value: isInvisible, ifTrue: 'invisible'));
    properties.add(new StringProperty('label', _label, defaultValue: ''));
    properties.add(new StringProperty('value', _value, defaultValue: ''));
    properties.add(new StringProperty('increasedValue', _increasedValue, defaultValue: ''));
    properties.add(new StringProperty('decreasedValue', _decreasedValue, defaultValue: ''));
    properties.add(new StringProperty('hint', _hint, defaultValue: ''));
    properties.add(new EnumProperty<TextDirection>('textDirection', _textDirection, defaultValue: null));
    properties.add(new IntProperty('nextNodeId', _nextNodeId, defaultValue: null));
    properties.add(new IntProperty('previousNodeId', _previousNodeId, defaultValue: null));
    properties.add(new DiagnosticsProperty<SemanticsSortOrder>('sortOrder', sortOrder, defaultValue: null));
    if (_textSelection?.isValid == true)
      properties.add(new MessageProperty('text selection', '[${_textSelection.start}, ${_textSelection.end}]'));
    properties.add(new DoubleProperty('scrollExtentMin', scrollExtentMin, defaultValue: null));
    properties.add(new DoubleProperty('scrollPosition', scrollPosition, defaultValue: null));
    properties.add(new DoubleProperty('scrollExtentMax', scrollExtentMax, defaultValue: null));
  }

  /// Returns a string representation of this node and its descendants.
  ///
  /// The order in which the children of the [SemanticsNode] will be printed is
  /// controlled by the [childOrder] parameter.
  @override
  String toStringDeep({
    String prefixLineOne: '',
    String prefixOtherLines,
    DiagnosticLevel minLevel: DiagnosticLevel.debug,
    DebugSemanticsDumpOrder childOrder: DebugSemanticsDumpOrder.geometricOrder,
  }) {
    assert(childOrder != null);
    return toDiagnosticsNode(childOrder: childOrder).toStringDeep(prefixLineOne: prefixLineOne, prefixOtherLines: prefixOtherLines, minLevel: minLevel);
  }

  @override
  DiagnosticsNode toDiagnosticsNode({
    String name,
    DiagnosticsTreeStyle style: DiagnosticsTreeStyle.sparse,
    DebugSemanticsDumpOrder childOrder: DebugSemanticsDumpOrder.geometricOrder,
  }) {
    return new _SemanticsDiagnosticableNode(
      name: name,
      value: this,
      style: style,
      childOrder: childOrder,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren({ DebugSemanticsDumpOrder childOrder: DebugSemanticsDumpOrder.inverseHitTest }) {
    return _getChildrenInOrder(childOrder)
      .map<DiagnosticsNode>((SemanticsNode node) => node.toDiagnosticsNode(childOrder: childOrder))
      .toList();
  }

  Iterable<SemanticsNode> _getChildrenInOrder(DebugSemanticsDumpOrder childOrder) {
    assert(childOrder != null);
    if (_children == null)
      return const <SemanticsNode>[];

    switch (childOrder) {
      case DebugSemanticsDumpOrder.geometricOrder:
        return new List<SemanticsNode>.from(_children)..sort(_geometryComparator);
      case DebugSemanticsDumpOrder.inverseHitTest:
        return _children;
    }
    assert(false);
    return null;
  }

  static int _geometryComparator(SemanticsNode a, SemanticsNode b) {
    final Rect rectA = a.transform == null ? a.rect : MatrixUtils.transformRect(a.transform, a.rect);
    final Rect rectB = b.transform == null ? b.rect : MatrixUtils.transformRect(b.transform, b.rect);
    final int top = rectA.top.compareTo(rectB.top);
    return top == 0 ? rectA.left.compareTo(rectB.left) : top;
  }
}

/// This class defines the comparison that is used to sort [SemanticsNode]s
/// before sending them to the platform side.
///
/// This is a helper class used to contain a [node], the effective
/// [order], the globally transformed starting corner [globalStartCorner],
/// and the containing node's [containerTextDirection] during the traversal of
/// the semantics node tree. A null value is allowed for [containerTextDirection],
/// because in that case we want to fall back to ordering by child insertion
/// order for nodes that are equal after sorting from top to bottom.
class _TraversalSortNode implements Comparable<_TraversalSortNode> {
  _TraversalSortNode(this.node, this.order, this.containerTextDirection, Matrix4 transform)
    : assert(node != null) {
    // When containerTextDirection is null, this is set to topLeft, but the x
    // coordinate is also ignored when doing the comparison in that case, so
    // this isn't actually expressing a directionality opinion.
    globalStartCorner = _transformPoint(
      containerTextDirection == TextDirection.rtl ? node.rect.topRight : node.rect.topLeft,
      transform,
    );
  }

  /// The node that this sort node represents.
  SemanticsNode node;

  /// The effective text direction for this node is the directionality that
  /// its container has.
  TextDirection containerTextDirection;

  /// This is the effective sort order for this node, taking into account its
  /// parents.
  SemanticsSortOrder order;

  /// The starting corner for the rectangle on this semantics node in
  /// global coordinates.
  ///
  /// When the container has the directionality [TextDirection.ltr], this is the
  /// upper left corner.  When the container has the directionality
  /// [TextDirection.rtl], this is the upper right corner. When the container
  /// has no directionality, this is set, but the x coordinate is ignored.
  Offset globalStartCorner;

  static Offset _transformPoint(Offset point, Matrix4 matrix) {
    final Vector3 result = matrix.transform3(new Vector3(point.dx, point.dy, 0.0));
    return new Offset(result.x, result.y);
  }

  /// Compares the node's start corner with that of `other`.
  ///
  /// Sorts top to bottom, and then start to end.
  ///
  /// This takes into account the container text direction, since the
  /// coordinate system has zero on the left, and we need to compare
  /// differently for different text directions.
  ///
  /// If no text direction is available (i.e. [containerTextDirection] is
  /// null), then we sort by vertical position first, and then by child
  /// insertion order.
  int _compareGeometry(_TraversalSortNode other) {
    final int verticalDiff = globalStartCorner.dy.compareTo(other.globalStartCorner.dy);
    if (verticalDiff != 0) {
      return verticalDiff;
    }
    switch (containerTextDirection) {
      case TextDirection.rtl:
        return other.globalStartCorner.dx.compareTo(globalStartCorner.dx);
      case TextDirection.ltr:
        return globalStartCorner.dx.compareTo(other.globalStartCorner.dx);
    }
    // In case containerTextDirection is null we fall back to child insertion order.
    return 0;
  }

  @override
  int compareTo(_TraversalSortNode other) {
    if (order == null || other?.order == null) {
      return _compareGeometry(other);
    }
    final int comparison = order.compareTo(other.order);
    if (comparison != 0) {
      return comparison;
    }
    return _compareGeometry(other);
  }
}

/// Owns [SemanticsNode] objects and notifies listeners of changes to the
/// render tree semantics.
///
/// To listen for semantic updates, call [PipelineOwner.ensureSemantics] to
/// obtain a [SemanticsHandle]. This will create a [SemanticsOwner] if
/// necessary.
class SemanticsOwner extends ChangeNotifier {
  final Set<SemanticsNode> _dirtyNodes = new Set<SemanticsNode>();
  final Map<int, SemanticsNode> _nodes = <int, SemanticsNode>{};
  final Set<SemanticsNode> _detachedNodes = new Set<SemanticsNode>();

  /// The root node of the semantics tree, if any.
  ///
  /// If the semantics tree is empty, returns null.
  SemanticsNode get rootSemanticsNode => _nodes[0];

  @override
  void dispose() {
    _dirtyNodes.clear();
    _nodes.clear();
    _detachedNodes.clear();
    super.dispose();
  }

  // Updates the nextNodeId and previousNodeId IDs on the semantics nodes. These
  // IDs are used on the platform side to order the nodes for traversal by the
  // accessibility services. If the nextNodeId or previousNodeId for a node
  // changes, the node will be marked as dirty.
  void _updateTraversalOrder() {
    final List<_TraversalSortNode> nodesInSemanticsTraversalOrder = <_TraversalSortNode>[];
    SemanticsSortOrder currentSortOrder = new SemanticsSortOrder(keys: <SemanticsSortKey>[]);
    Matrix4 currentTransform = new Matrix4.identity();
    TextDirection currentTextDirection = rootSemanticsNode.textDirection;
    bool visitor(SemanticsNode node) {
      final SemanticsSortOrder previousOrder = currentSortOrder;
      final Matrix4 previousTransform = currentTransform.clone();
      if (node.sortOrder != null) {
        currentSortOrder = currentSortOrder.merge(node.sortOrder);
      }
      if (node.transform != null) {
        currentTransform.multiply(node.transform);
      }
      final _TraversalSortNode traversalNode = new _TraversalSortNode(
        node,
        currentSortOrder,
        currentTextDirection,
        currentTransform,
      );
      // The text direction in force here is the parent's text direction.
      nodesInSemanticsTraversalOrder.add(traversalNode);
      if (node.hasChildren) {
        final TextDirection previousTextDirection = currentTextDirection;
        currentTextDirection = node.textDirection;
        // Now visit the children with this node's text direction in force.
        node.visitChildren(visitor);
        currentTextDirection = previousTextDirection;
      }
      currentSortOrder = previousOrder;
      currentTransform = previousTransform;
      return true;
    }
    rootSemanticsNode.visitChildren(visitor);

    if (nodesInSemanticsTraversalOrder.isEmpty)
      return;

    nodesInSemanticsTraversalOrder.sort();
    _TraversalSortNode node = nodesInSemanticsTraversalOrder.removeLast();
    node.node._updateNextNodeId(-1);
    while (nodesInSemanticsTraversalOrder.isNotEmpty) {
      final _TraversalSortNode previousNode = nodesInSemanticsTraversalOrder.removeLast();
      node.node._updatePreviousNodeId(previousNode.node.id);
      previousNode.node._updateNextNodeId(node.node.id);
      node = previousNode;
    }
    node.node._updatePreviousNodeId(-1);
  }

  /// Update the semantics using [Window.updateSemantics].
  void sendSemanticsUpdate() {
    if (_dirtyNodes.isEmpty)
      return;
    // Nodes that change their previousNodeId will be marked as dirty.
    _updateTraversalOrder();
    final List<SemanticsNode> visitedNodes = <SemanticsNode>[];
    while (_dirtyNodes.isNotEmpty) {
      final List<SemanticsNode> localDirtyNodes = _dirtyNodes.where((SemanticsNode node) => !_detachedNodes.contains(node)).toList();
      _dirtyNodes.clear();
      _detachedNodes.clear();
      localDirtyNodes.sort((SemanticsNode a, SemanticsNode b) => a.depth - b.depth);
      visitedNodes.addAll(localDirtyNodes);
      for (SemanticsNode node in localDirtyNodes) {
        assert(node._dirty);
        assert(node.parent == null || !node.parent.isPartOfNodeMerging || node.isMergedIntoParent);
        if (node.isPartOfNodeMerging) {
          assert(node.mergeAllDescendantsIntoThisNode || node.parent != null);
          // if we're merged into our parent, make sure our parent is added to the dirty list
          if (node.parent != null && node.parent.isPartOfNodeMerging)
            node.parent._markDirty(); // this can add the node to the dirty list
        }
      }
    }
    visitedNodes.sort((SemanticsNode a, SemanticsNode b) => a.depth - b.depth);
    final ui.SemanticsUpdateBuilder builder = new ui.SemanticsUpdateBuilder();
    for (SemanticsNode node in visitedNodes) {
      assert(node.parent?._dirty != true); // could be null (no parent) or false (not dirty)
      // The _serialize() method marks the node as not dirty, and
      // recurses through the tree to do a deep serialization of all
      // contiguous dirty nodes. This means that when we return here,
      // it's quite possible that subsequent nodes are no longer
      // dirty. We skip these here.
      // We also skip any nodes that were reset and subsequently
      // dropped entirely (RenderObject.markNeedsSemanticsUpdate()
      // calls reset() on its SemanticsNode if onlyChanges isn't set,
      // which happens e.g. when the node is no longer contributing
      // semantics).
      if (node._dirty && node.attached)
        node._addToUpdate(builder);
    }
    _dirtyNodes.clear();
    ui.window.updateSemantics(builder.build());
    notifyListeners();
  }

  _SemanticsActionHandler _getSemanticsActionHandlerForId(int id, SemanticsAction action) {
    SemanticsNode result = _nodes[id];
    if (result != null && result.isPartOfNodeMerging && !result._canPerformAction(action)) {
      result._visitDescendants((SemanticsNode node) {
        if (node._canPerformAction(action)) {
          result = node;
          return false; // found node, abort walk
        }
        return true; // continue walk
      });
    }
    if (result == null || !result._canPerformAction(action))
      return null;
    return result._actions[action];
  }

  /// Asks the [SemanticsNode] with the given id to perform the given action.
  ///
  /// If the [SemanticsNode] has not indicated that it can perform the action,
  /// this function does nothing.
  ///
  /// If the given `action` requires arguments they need to be passed in via
  /// the `args` parameter.
  void performAction(int id, SemanticsAction action, [dynamic args]) {
    assert(action != null);
    final _SemanticsActionHandler handler = _getSemanticsActionHandlerForId(id, action);
    if (handler != null) {
      handler(args);
      return;
    }

    // Default actions if no [handler] was provided.
    if (action == SemanticsAction.showOnScreen && _nodes[id]._showOnScreen != null)
      _nodes[id]._showOnScreen();
  }

  _SemanticsActionHandler _getSemanticsActionHandlerForPosition(SemanticsNode node, Offset position, SemanticsAction action) {
    if (node.transform != null) {
      final Matrix4 inverse = new Matrix4.identity();
      if (inverse.copyInverse(node.transform) == 0.0)
        return null;
      position = MatrixUtils.transformPoint(inverse, position);
    }
    if (!node.rect.contains(position))
      return null;
    if (node.mergeAllDescendantsIntoThisNode) {
      SemanticsNode result;
      node._visitDescendants((SemanticsNode child) {
        if (child._canPerformAction(action)) {
          result = child;
          return false;
        }
        return true;
      });
      return result?._actions[action];
    }
    if (node.hasChildren) {
      for (SemanticsNode child in node._children.reversed) {
        final _SemanticsActionHandler handler = _getSemanticsActionHandlerForPosition(child, position, action);
        if (handler != null)
          return handler;
      }
    }
    return node._actions[action];
  }

  /// Asks the [SemanticsNode] at the given position to perform the given action.
  ///
  /// If the [SemanticsNode] has not indicated that it can perform the action,
  /// this function does nothing.
  ///
  /// If the given `action` requires arguments they need to be passed in via
  /// the `args` parameter.
  void performActionAt(Offset position, SemanticsAction action, [dynamic args]) {
    assert(action != null);
    final SemanticsNode node = rootSemanticsNode;
    if (node == null)
      return;
    final _SemanticsActionHandler handler = _getSemanticsActionHandlerForPosition(node, position, action);
    if (handler != null)
      handler(args);
  }

  @override
  String toString() => describeIdentity(this);
}

/// Describes the semantic information associated with the owning
/// [RenderObject].
///
/// The information provided in the configuration is used to to generate the
/// semantics tree.
class SemanticsConfiguration {

  // SEMANTIC BOUNDARY BEHAVIOR

  /// Whether the [RenderObject] owner of this configuration wants to own its
  /// own [SemanticsNode].
  ///
  /// When set to true semantic information associated with the [RenderObject]
  /// owner of this configuration or any of its descendants will not leak into
  /// parents. The [SemanticsNode] generated out of this configuration will
  /// act as a boundary.
  ///
  /// Whether descendants of the owning [RenderObject] can add their semantic
  /// information to the [SemanticsNode] introduced by this configuration
  /// is controlled by [explicitChildNodes].
  ///
  /// This has to be true if [isMergingDescendantsIntoOneNode] is also true.
  bool get isSemanticBoundary => _isSemanticBoundary;
  bool _isSemanticBoundary = false;
  set isSemanticBoundary(bool value) {
    assert(!isMergingSemanticsOfDescendants || value);
    _isSemanticBoundary = value;
  }

  /// Whether the configuration forces all children of the owning [RenderObject]
  /// that want to contribute semantic information to the semantics tree to do
  /// so in the form of explicit [SemanticsNode]s.
  ///
  /// When set to false children of the owning [RenderObject] are allowed to
  /// annotate [SemanticNode]s of their parent with the semantic information
  /// they want to contribute to the semantic tree.
  /// When set to true the only way for children of the owning [RenderObject]
  /// to contribute semantic information to the semantic tree is to introduce
  /// new explicit [SemanticNode]s to the tree.
  ///
  /// This setting is often used in combination with [isSemanticBoundary] to
  /// create semantic boundaries that are either writable or not for children.
  bool explicitChildNodes = false;

  /// Whether the owning [RenderObject] makes other [RenderObject]s previously
  /// painted within the same semantic boundary unreachable for accessibility
  /// purposes.
  ///
  /// If set to true, the semantic information for all siblings and cousins of
  /// this node, that are earlier in a depth-first pre-order traversal, are
  /// dropped from the semantics tree up until a semantic boundary (as defined
  /// by [isSemanticBoundary]) is reached.
  ///
  /// If [isSemanticBoundary] and [isBlockingSemanticsOfPreviouslyPaintedNodes]
  /// is set on the same node, all previously painted siblings and cousins up
  /// until the next ancestor that is a semantic boundary are dropped.
  ///
  /// Paint order as established by [visitChildrenForSemantics] is used to
  /// determine if a node is previous to this one.
  bool isBlockingSemanticsOfPreviouslyPaintedNodes = false;

  // SEMANTIC ANNOTATIONS
  // These will end up on [SemanticNode]s generated from
  // [SemanticsConfiguration]s.

  /// Whether this configuration is empty.
  ///
  /// An empty configuration doesn't contain any semantic information that it
  /// wants to contribute to the semantics tree.
  bool get hasBeenAnnotated => _hasBeenAnnotated;
  bool _hasBeenAnnotated = false;

  /// The actions (with associated action handlers) that this configuration
  /// would like to contribute to the semantics tree.
  ///
  /// See also:
  ///
  /// * [addAction] to add an action.
  final Map<SemanticsAction, _SemanticsActionHandler> _actions = <SemanticsAction, _SemanticsActionHandler>{};

  int _actionsAsBits = 0;

  /// Adds an `action` to the semantics tree.
  ///
  /// The provided `handler` is called to respond to the user triggered
  /// `action`.
  void _addAction(SemanticsAction action, _SemanticsActionHandler handler) {
    assert(handler != null);
    _actions[action] = handler;
    _actionsAsBits |= action.index;
    _hasBeenAnnotated = true;
  }

  /// Adds an `action` to the semantics tree, whose `handler` does not expect
  /// any arguments.
  ///
  /// The provided `handler` is called to respond to the user triggered
  /// `action`.
  void _addArgumentlessAction(SemanticsAction action, VoidCallback handler) {
    assert(handler != null);
    _addAction(action, (dynamic args) {
      assert(args == null);
      handler();
    });
  }

  /// The handler for [SemanticsAction.tap].
  ///
  /// This is the semantic equivalent of a user briefly tapping the screen with
  /// the finger without moving it. For example, a button should implement this
  /// action.
  ///
  /// VoiceOver users on iOS and TalkBack users on Android can trigger this
  /// action by double-tapping the screen while an element is focused.
  ///
  /// On Android prior to Android Oreo a double-tap on the screen while an
  /// element with an [onTap] handler is focused will not call the registered
  /// handler. Instead, Android will simulate a pointer down and up event at the
  /// center of the focused element. Those pointer events will get dispatched
  /// just like a regular tap with TalkBack disabled would: The events will get
  /// processed by any [GestureDetector] listening for gestures in the center of
  /// the focused element. Therefore, to ensure that [onTap] handlers work
  /// properly on Android versions prior to Oreo, a [GestureDetector] with an
  /// onTap handler should always be wrapping an element that defines a
  /// semantic [onTap] handler. By default a [GestureDetector] will register its
  /// own semantic [onTap] handler that follows this principle.
  VoidCallback get onTap => _onTap;
  VoidCallback _onTap;
  set onTap(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.tap, value);
    _onTap = value;
  }

  /// The handler for [SemanticsAction.longPress].
  ///
  /// This is the semantic equivalent of a user pressing and holding the screen
  /// with the finger for a few seconds without moving it.
  ///
  /// VoiceOver users on iOS and TalkBack users on Android can trigger this
  /// action by double-tapping the screen without lifting the finger after the
  /// second tap.
  VoidCallback get onLongPress => _onLongPress;
  VoidCallback _onLongPress;
  set onLongPress(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.longPress, value);
    _onLongPress = value;
  }

  /// The handler for [SemanticsAction.scrollLeft].
  ///
  /// This is the semantic equivalent of a user moving their finger across the
  /// screen from right to left. It should be recognized by controls that are
  /// horizontally scrollable.
  ///
  /// VoiceOver users on iOS can trigger this action by swiping left with three
  /// fingers. TalkBack users on Android can trigger this action by swiping
  /// right and then left in one motion path. On Android, [onScrollUp] and
  /// [onScrollLeft] share the same gesture. Therefore, only on of them should
  /// be provided.
  VoidCallback get onScrollLeft => _onScrollLeft;
  VoidCallback _onScrollLeft;
  set onScrollLeft(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.scrollLeft, value);
    _onScrollLeft = value;
  }

  /// The handler for [SemanticsAction.scrollRight].
  ///
  /// This is the semantic equivalent of a user moving their finger across the
  /// screen from left to right. It should be recognized by controls that are
  /// horizontally scrollable.
  ///
  /// VoiceOver users on iOS can trigger this action by swiping right with three
  /// fingers. TalkBack users on Android can trigger this action by swiping
  /// left and then right in one motion path. On Android, [onScrollDown] and
  /// [onScrollRight] share the same gesture. Therefore, only on of them should
  /// be provided.
  VoidCallback get onScrollRight => _onScrollRight;
  VoidCallback _onScrollRight;
  set onScrollRight(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.scrollRight, value);
    _onScrollRight = value;
  }

  /// The handler for [SemanticsAction.scrollUp].
  ///
  /// This is the semantic equivalent of a user moving their finger across the
  /// screen from bottom to top. It should be recognized by controls that are
  /// vertically scrollable.
  ///
  /// VoiceOver users on iOS can trigger this action by swiping up with three
  /// fingers. TalkBack users on Android can trigger this action by swiping
  /// right and then left in one motion path. On Android, [onScrollUp] and
  /// [onScrollLeft] share the same gesture. Therefore, only on of them should
  /// be provided.
  VoidCallback get onScrollUp => _onScrollUp;
  VoidCallback _onScrollUp;
  set onScrollUp(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.scrollUp, value);
    _onScrollUp = value;
  }

  /// The handler for [SemanticsAction.scrollDown].
  ///
  /// This is the semantic equivalent of a user moving their finger across the
  /// screen from top to bottom. It should be recognized by controls that are
  /// vertically scrollable.
  ///
  /// VoiceOver users on iOS can trigger this action by swiping down with three
  /// fingers. TalkBack users on Android can trigger this action by swiping
  /// left and then right in one motion path. On Android, [onScrollDown] and
  /// [onScrollRight] share the same gesture. Therefore, only on of them should
  /// be provided.
  VoidCallback get onScrollDown => _onScrollDown;
  VoidCallback _onScrollDown;
  set onScrollDown(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.scrollDown, value);
    _onScrollDown = value;
  }

  /// The handler for [SemanticsAction.increase].
  ///
  /// This is a request to increase the value represented by the widget. For
  /// example, this action might be recognized by a slider control.
  ///
  /// If a [value] is set, [increasedValue] must also be provided and
  /// [onIncrease] must ensure that [value] will be set to [increasedValue].
  ///
  /// VoiceOver users on iOS can trigger this action by swiping up with one
  /// finger. TalkBack users on Android can trigger this action by pressing the
  /// volume up button.
  VoidCallback get onIncrease => _onIncrease;
  VoidCallback _onIncrease;
  set onIncrease(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.increase, value);
    _onIncrease = value;
  }

  /// The handler for [SemanticsAction.decrease].
  ///
  /// This is a request to decrease the value represented by the widget. For
  /// example, this action might be recognized by a slider control.
  ///
  /// If a [value] is set, [decreasedValue] must also be provided and
  /// [onDecrease] must ensure that [value] will be set to [decreasedValue].
  ///
  /// VoiceOver users on iOS can trigger this action by swiping down with one
  /// finger. TalkBack users on Android can trigger this action by pressing the
  /// volume down button.
  VoidCallback get onDecrease => _onDecrease;
  VoidCallback _onDecrease;
  set onDecrease(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.decrease, value);
    _onDecrease = value;
  }

  /// The handler for [SemanticsAction.copy].
  ///
  /// This is a request to copy the current selection to the clipboard.
  ///
  /// TalkBack users on Android can trigger this action from the local context
  /// menu of a text field, for example.
  VoidCallback get onCopy => _onCopy;
  VoidCallback _onCopy;
  set onCopy(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.copy, value);
    _onCopy = value;
  }

  /// The handler for [SemanticsAction.cut].
  ///
  /// This is a request to cut the current selection and place it in the
  /// clipboard.
  ///
  /// TalkBack users on Android can trigger this action from the local context
  /// menu of a text field, for example.
  VoidCallback get onCut => _onCut;
  VoidCallback _onCut;
  set onCut(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.cut, value);
    _onCut = value;
  }

  /// The handler for [SemanticsAction.paste].
  ///
  /// This is a request to paste the current content of the clipboard.
  ///
  /// TalkBack users on Android can trigger this action from the local context
  /// menu of a text field, for example.
  VoidCallback get onPaste => _onPaste;
  VoidCallback _onPaste;
  set onPaste(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.paste, value);
    _onPaste = value;
  }

  /// The handler for [SemanticsAction.showOnScreen].
  ///
  /// A request to fully show the semantics node on screen. For example, this
  /// action might be send to a node in a scrollable list that is partially off
  /// screen to bring it on screen.
  ///
  /// For elements in a scrollable list the framework provides a default
  /// implementation for this action and it is not advised to provide a
  /// custom one via this setter.
  VoidCallback get onShowOnScreen => _onShowOnScreen;
  VoidCallback _onShowOnScreen;
  set onShowOnScreen(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.showOnScreen, value);
    _onShowOnScreen = value;
  }

  /// The handler for [SemanticsAction.onMoveCursorForwardByCharacter].
  ///
  /// This handler is invoked when the user wants to move the cursor in a
  /// text field forward by one character.
  ///
  /// TalkBack users can trigger this by pressing the volume up key while the
  /// input focus is in a text field.
  MoveCursorHandler get onMoveCursorForwardByCharacter => _onMoveCursorForwardByCharacter;
  MoveCursorHandler _onMoveCursorForwardByCharacter;
  set onMoveCursorForwardByCharacter(MoveCursorHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.moveCursorForwardByCharacter, (dynamic args) {
      final bool extentSelection = args;
      assert(extentSelection != null);
      value(extentSelection);
    });
    _onMoveCursorForwardByCharacter = value;
  }

  /// The handler for [SemanticsAction.onMoveCursorBackwardByCharacter].
  ///
  /// This handler is invoked when the user wants to move the cursor in a
  /// text field backward by one character.
  ///
  /// TalkBack users can trigger this by pressing the volume down key while the
  /// input focus is in a text field.
  MoveCursorHandler get onMoveCursorBackwardByCharacter => _onMoveCursorBackwardByCharacter;
  MoveCursorHandler _onMoveCursorBackwardByCharacter;
  set onMoveCursorBackwardByCharacter(MoveCursorHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.moveCursorBackwardByCharacter, (dynamic args) {
      final bool extentSelection = args;
      assert(extentSelection != null);
      value(extentSelection);
    });
    _onMoveCursorBackwardByCharacter = value;
  }

  /// The handler for [SemanticsAction.setSelection].
  ///
  /// This handler is invoked when the user either wants to change the currently
  /// selected text in a text field or change the position of the cursor.
  ///
  /// TalkBack users can trigger this handler by selecting "Move cursor to
  /// beginning/end" or "Select all" from the local context menu.
  SetSelectionHandler get onSetSelection => _onSetSelection;
  SetSelectionHandler _onSetSelection;
  set onSetSelection(SetSelectionHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.setSelection, (dynamic args) {
      final Map<String, int> selection = args;
      assert(selection != null && selection['base'] != null && selection['extent'] != null);
      value(new TextSelection(
        baseOffset: selection['base'],
        extentOffset: selection['extent'],
      ));
    });
    _onSetSelection = value;
  }

  /// The handler for [SemanticsAction.didGainAccessibilityFocus].
  ///
  /// This handler is invoked when the node annotated with this handler gains
  /// the accessibility focus. The accessibility focus is the
  /// green (on Android with TalkBack) or black (on iOS with VoiceOver)
  /// rectangle shown on screen to indicate what element an accessibility
  /// user is currently interacting with.
  ///
  /// The accessibility focus is different from the input focus. The input focus
  /// is usually held by the element that currently responds to keyboard inputs.
  /// Accessibility focus and input focus can be held by two different nodes!
  ///
  /// See also:
  ///
  ///  * [onDidLoseAccessibilityFocus], which is invoked when the accessibility
  ///    focus is removed from the node
  ///  * [FocusNode], [FocusScope], [FocusManager], which manage the input focus
  VoidCallback get onDidGainAccessibilityFocus => _onDidGainAccessibilityFocus;
  VoidCallback _onDidGainAccessibilityFocus;
  set onDidGainAccessibilityFocus(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.didGainAccessibilityFocus, value);
    _onDidGainAccessibilityFocus = value;
  }

  /// The handler for [SemanticsAction.didLoseAccessibilityFocus].
  ///
  /// This handler is invoked when the node annotated with this handler
  /// loses the accessibility focus. The accessibility focus is
  /// the green (on Android with TalkBack) or black (on iOS with VoiceOver)
  /// rectangle shown on screen to indicate what element an accessibility
  /// user is currently interacting with.
  ///
  /// The accessibility focus is different from the input focus. The input focus
  /// is usually held by the element that currently responds to keyboard inputs.
  /// Accessibility focus and input focus can be held by two different nodes!
  ///
  /// See also:
  ///
  ///  * [onDidGainAccessibilityFocus], which is invoked when the node gains
  ///    accessibility focus
  ///  * [FocusNode], [FocusScope], [FocusManager], which manage the input focus
  VoidCallback get onDidLoseAccessibilityFocus => _onDidLoseAccessibilityFocus;
  VoidCallback _onDidLoseAccessibilityFocus;
  set onDidLoseAccessibilityFocus(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.didLoseAccessibilityFocus, value);
    _onDidLoseAccessibilityFocus = value;
  }

  /// Returns the action handler registered for [action] or null if none was
  /// registered.
  ///
  /// See also:
  ///
  ///  * [addAction] to add an action.
  _SemanticsActionHandler getActionHandler(SemanticsAction action) => _actions[action];

  /// The semantics traversal order.
  ///
  /// This is used to sort this semantic node with all other semantic
  /// nodes to determine the traversal order of accessible nodes.
  ///
  /// See also:
  ///
  ///  * [SemanticsSortOrder], which manages a list of sort keys.
  SemanticsSortOrder get sortOrder => _sortOrder;
  SemanticsSortOrder _sortOrder;
  set sortOrder(SemanticsSortOrder value) {
    assert(value != null);
    _sortOrder = value;
    _hasBeenAnnotated = true;
  }

  /// Whether the semantic information provided by the owning [RenderObject] and
  /// all of its descendants should be treated as one logical entity.
  ///
  /// If set to true, the descendants of the owning [RenderObject]'s
  /// [SemanticsNode] will merge their semantic information into the
  /// [SemanticsNode] representing the owning [RenderObject].
  ///
  /// Setting this to true requires that [isSemanticBoundary] is also true.
  bool get isMergingSemanticsOfDescendants => _isMergingSemanticsOfDescendants;
  bool _isMergingSemanticsOfDescendants = false;
  set isMergingSemanticsOfDescendants(bool value) {
    assert(isSemanticBoundary);
    _isMergingSemanticsOfDescendants = value;
    _hasBeenAnnotated = true;
  }

  /// A textual description of the owning [RenderObject].
  ///
  /// On iOS this is used for the `accessibilityLabel` property defined in the
  /// `UIAccessibility` Protocol. On Android it is concatenated together with
  /// [value] and [hint] in the following order: [value], [label], [hint].
  /// The concatenated value is then used as the `Text` description.
  ///
  /// The reading direction is given by [textDirection].
  String get label => _label;
  String _label = '';
  set label(String label) {
    assert(label != null);
    _label = label;
    _hasBeenAnnotated = true;
  }

  /// A textual description for the current value of the owning [RenderObject].
  ///
  /// On iOS this is used for the `accessibilityValue` property defined in the
  /// `UIAccessibility` Protocol. On Android it is concatenated together with
  /// [label] and [hint] in the following order: [value], [label], [hint].
  /// The concatenated value is then used as the `Text` description.
  ///
  /// The reading direction is given by [textDirection].
  ///
  /// See also:
  ///
  ///  * [decreasedValue], describes what [value] will be after performing
  ///    [SemanticsAction.decrease]
  ///  * [increasedValue], describes what [value] will be after performing
  ///    [SemanticsAction.increase]
  String get value => _value;
  String _value = '';
  set value(String value) {
    assert(value != null);
    _value = value;
    _hasBeenAnnotated = true;
  }

  /// The value that [value] will have after performing a
  /// [SemanticsAction.decrease] action.
  ///
  /// This must be set if a handler for [SemanticsAction.decrease] is provided
  /// and [value] is set.
  ///
  /// The reading direction is given by [textDirection].
  String get decreasedValue => _decreasedValue;
  String _decreasedValue = '';
  set decreasedValue(String decreasedValue) {
    assert(decreasedValue != null);
    _decreasedValue = decreasedValue;
    _hasBeenAnnotated = true;
  }

  /// The value that [value] will have after performing a
  /// [SemanticsAction.increase] action.
  ///
  /// This must be set if a handler for [SemanticsAction.increase] is provided
  /// and [value] is set.
  ///
  /// The reading direction is given by [textDirection].
  String get increasedValue => _increasedValue;
  String _increasedValue = '';
  set increasedValue(String increasedValue) {
    assert(increasedValue != null);
    _increasedValue = increasedValue;
    _hasBeenAnnotated = true;
  }

  /// A brief description of the result of performing an action on this node.
  ///
  /// On iOS this is used for the `accessibilityHint` property defined in the
  /// `UIAccessibility` Protocol. On Android it is concatenated together with
  /// [label] and [value] in the following order: [value], [label], [hint].
  /// The concatenated value is then used as the `Text` description.
  ///
  /// The reading direction is given by [textDirection].
  String get hint => _hint;
  String _hint = '';
  set hint(String hint) {
    assert(hint != null);
    _hint = hint;
    _hasBeenAnnotated = true;
  }

  /// The reading direction for the text in [label], [value], [hint],
  /// [increasedValue], and [decreasedValue].
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection textDirection) {
    _textDirection = textDirection;
    _hasBeenAnnotated = true;
  }

  /// Whether the owning [RenderObject] is selected (true) or not (false).
  bool get isSelected => _hasFlag(SemanticsFlag.isSelected);
  set isSelected(bool value) {
    _setFlag(SemanticsFlag.isSelected, value);
  }

  /// Whether the owning [RenderObject] is currently enabled.
  ///
  /// A disabled object does not respond to user interactions. Only objects that
  /// usually respond to user interactions, but which currently do not (like a
  /// disabled button) should be marked as disabled.
  ///
  /// The setter should not be called for objects (like static text) that never
  /// respond to user interactions.
  ///
  /// The getter will return null if the owning [RenderObject] doesn't support
  /// the concept of being enabled/disabled.
  bool get isEnabled => _hasFlag(SemanticsFlag.hasEnabledState) ? _hasFlag(SemanticsFlag.isEnabled) : null;
  set isEnabled(bool value) {
    _setFlag(SemanticsFlag.hasEnabledState, true);
    _setFlag(SemanticsFlag.isEnabled, value);
  }

  /// If this node has Boolean state that can be controlled by the user, whether
  /// that state is on or off, corresponding to true and false, respectively.
  ///
  /// Do not call the setter for this field if the owning [RenderObject] doesn't
  /// have checked/unchecked state that can be controlled by the user.
  ///
  /// The getter returns null if the owning [RenderObject] does not have
  /// checked/unchecked state.
  bool get isChecked => _hasFlag(SemanticsFlag.hasCheckedState) ? _hasFlag(SemanticsFlag.isChecked) : null;
  set isChecked(bool value) {
    _setFlag(SemanticsFlag.hasCheckedState, true);
    _setFlag(SemanticsFlag.isChecked, value);
  }

  /// Whether the owning RenderObject corresponds to UI that allows the user to
  /// pick one of several mutually exclusive options.
  ///
  /// For example, a [Radio] button is in a mutually exclusive group because
  /// only one radio button in that group can be marked as [isChecked].
  bool get isInMutuallyExclusiveGroup => _hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup);
  set isInMutuallyExclusiveGroup(bool value) {
    _setFlag(SemanticsFlag.isInMutuallyExclusiveGroup, value);
  }

  /// Whether the owning [RenderObject] currently holds the user's focus.
  bool get isFocused => _hasFlag(SemanticsFlag.isFocused);
  set isFocused(bool value) {
    _setFlag(SemanticsFlag.isFocused, value);
  }

  /// Whether the owning [RenderObject] is a button (true) or not (false).
  bool get isButton => _hasFlag(SemanticsFlag.isButton);
  set isButton(bool value) {
    _setFlag(SemanticsFlag.isButton, value);
  }

  /// Whether the owning [RenderObject] is a header (true) or not (false).
  bool get isHeader => _hasFlag(SemanticsFlag.isHeader);
  set isHeader(bool value) {
    _setFlag(SemanticsFlag.isHeader, value);
  }

  /// Whether the owning [RenderObject] is a text field.
  bool get isTextField => _hasFlag(SemanticsFlag.isTextField);
  set isTextField(bool value) {
    _setFlag(SemanticsFlag.isTextField, value);
  }

  /// The currently selected text (or the position of the cursor) within [value]
  /// if this node represents a text field.
  TextSelection get textSelection => _textSelection;
  TextSelection _textSelection;
  set textSelection(TextSelection value) {
    assert(value != null);
    _textSelection = value;
    _hasBeenAnnotated = true;
  }

  /// Indicates the current scrolling position in logical pixels if the node is
  /// scrollable.
  ///
  /// The properties [scrollExtentMin] and [scrollExtentMax] indicate the valid
  /// in-range values for this property. The value for [scrollPosition] may
  /// (temporarily) be outside that range, e.g. during an overscroll.
  ///
  /// See also:
  ///
  ///  * [ScrollPosition.pixels], from where this value is usually taken.
  double get scrollPosition => _scrollPosition;
  double _scrollPosition;
  set scrollPosition(double value) {
    assert(value != null);
    _scrollPosition = value;
    _hasBeenAnnotated = true;
  }

  /// Indicates the maximum in-range value for [scrollPosition] if the node is
  /// scrollable.
  ///
  /// This value may be infinity if the scroll is unbound.
  ///
  /// See also:
  ///
  ///  * [ScrollPosition.maxScrollExtent], from where this value is usually taken.
  double get scrollExtentMax => _scrollExtentMax;
  double _scrollExtentMax;
  set scrollExtentMax(double value) {
    assert(value != null);
    _scrollExtentMax = value;
    _hasBeenAnnotated = true;
  }

  /// Indicates the minimum in-range value for [scrollPosition] if the node is
  /// scrollable.
  ///
  /// This value may be infinity if the scroll is unbound.
  ///
  /// See also:
  ///
  ///  * [ScrollPosition.minScrollExtent], from where this value is usually taken.
  double get scrollExtentMin => _scrollExtentMin;
  double _scrollExtentMin;
  set scrollExtentMin(double value) {
    assert(value != null);
    _scrollExtentMin = value;
    _hasBeenAnnotated = true;
  }

  // TAGS

  /// The set of tags that this configuration wants to add to all child
  /// [SemanticsNode]s.
  ///
  /// See also:
  ///
  ///  * [addTagForChildren] to add a tag and for more information about their
  ///    usage.
  Iterable<SemanticsTag> get tagsForChildren => _tagsForChildren;
  Set<SemanticsTag> _tagsForChildren;

  /// Specifies a [SemanticsTag] that this configuration wants to apply to all
  /// child [SemanticsNode]s.
  ///
  /// The tag is added to all [SemanticsNode] that pass through the
  /// [RenderObject] owning this configuration while looking to be attached to a
  /// parent [SemanticsNode].
  ///
  /// Tags are used to communicate to a parent [SemanticsNode] that a child
  /// [SemanticsNode] was passed through a particular [RenderObject]. The parent
  /// can use this information to determine the shape of the semantics tree.
  ///
  /// See also:
  ///
  ///  * [RenderSemanticsGestureHandler.excludeFromScrolling] for an example of
  ///    how tags are used.
  void addTagForChildren(SemanticsTag tag) {
    _tagsForChildren ??= new Set<SemanticsTag>();
    _tagsForChildren.add(tag);
  }

  // INTERNAL FLAG MANAGEMENT

  int _flags = 0;
  void _setFlag(SemanticsFlag flag, bool value) {
    if (value) {
      _flags |= flag.index;
    } else {
      _flags &= ~flag.index;
    }
    _hasBeenAnnotated = true;
  }

  bool _hasFlag(SemanticsFlag flag) => (_flags & flag.index) != 0;

  // CONFIGURATION COMBINATION LOGIC

  /// Whether this configuration is compatible with the provided `other`
  /// configuration.
  ///
  /// Two configurations are said to be compatible if they can be added to the
  /// same [SemanticsNode] without losing any semantics information.
  bool isCompatibleWith(SemanticsConfiguration other) {
    if (other == null || !other.hasBeenAnnotated || !hasBeenAnnotated)
      return true;
    if (_actionsAsBits & other._actionsAsBits != 0)
      return false;
    if ((_flags & other._flags) != 0)
      return false;
    if (_value != null && _value.isNotEmpty && other._value != null && other._value.isNotEmpty)
      return false;
    return true;
  }

  /// Absorb the semantic information from `other` into this configuration.
  ///
  /// This adds the semantic information of both configurations and saves the
  /// result in this configuration.
  ///
  /// Only configurations that have [explicitChildNodes] set to false can
  /// absorb other configurations and it is recommended to only absorb compatible
  /// configurations as determined by [isCompatibleWith].
  void absorb(SemanticsConfiguration other) {
    assert(!explicitChildNodes);

    if (!other.hasBeenAnnotated)
      return;

    _actions.addAll(other._actions);
    _actionsAsBits |= other._actionsAsBits;
    _flags |= other._flags;
    _textSelection ??= other._textSelection;
    _scrollPosition ??= other._scrollPosition;
    _scrollExtentMax ??= other._scrollExtentMax;
    _scrollExtentMin ??= other._scrollExtentMin;

    textDirection ??= other.textDirection;
    _sortOrder = _sortOrder?.merge(other._sortOrder);
    _label = _concatStrings(
      thisString: _label,
      thisTextDirection: textDirection,
      otherString: other._label,
      otherTextDirection: other.textDirection,
    );
    if (_decreasedValue == '' || _decreasedValue == null)
      _decreasedValue = other._decreasedValue;
    if (_value == '' || _value == null)
      _value = other._value;
    if (_increasedValue == '' || _increasedValue == null)
      _increasedValue = other._increasedValue;
    _hint = _concatStrings(
      thisString: _hint,
      thisTextDirection: textDirection,
      otherString: other._hint,
      otherTextDirection: other.textDirection,
    );

    _hasBeenAnnotated = _hasBeenAnnotated || other._hasBeenAnnotated;
  }

  /// Returns an exact copy of this configuration.
  SemanticsConfiguration copy() {
    return new SemanticsConfiguration()
      .._isSemanticBoundary = _isSemanticBoundary
      ..explicitChildNodes = explicitChildNodes
      ..isBlockingSemanticsOfPreviouslyPaintedNodes = isBlockingSemanticsOfPreviouslyPaintedNodes
      .._hasBeenAnnotated = _hasBeenAnnotated
      .._isMergingSemanticsOfDescendants = _isMergingSemanticsOfDescendants
      .._textDirection = _textDirection
      .._sortOrder = _sortOrder
      .._label = _label
      .._increasedValue = _increasedValue
      .._value = _value
      .._decreasedValue = _decreasedValue
      .._hint = _hint
      .._flags = _flags
      .._tagsForChildren = _tagsForChildren
      .._textSelection = _textSelection
      .._scrollPosition = _scrollPosition
      .._scrollExtentMax = _scrollExtentMax
      .._scrollExtentMin = _scrollExtentMin
      .._actionsAsBits = _actionsAsBits
      .._actions.addAll(_actions);
  }
}

/// Used by [debugDumpSemanticsTree] to specify the order in which child nodes
/// are printed.
enum DebugSemanticsDumpOrder {
  /// Print nodes in inverse hit test order.
  ///
  /// In inverse hit test order, the last child of a [SemanticsNode] will be
  /// asked first if it wants to respond to a user's interaction, followed by
  /// the second last, etc. until a taker is found.
  inverseHitTest,

  /// Print nodes in geometric traversal order.
  ///
  /// Geometric traversal order is the default traversal order for semantics nodes which
  /// don't have [SemanticsNode.sortOrder] set.  This traversal order ignores the node
  /// sort order, since the diagnostics system follows the widget tree and can only sort
  /// a node's children, and the semantics system sorts nodes globally.
  geometricOrder,

  // TODO(gspencer): Add support to toStringDeep (and others) to print the tree in
  // the actual traversal order that the user will experience.  This requires sorting
  // nodes globally before printing, not just the children.
}

String _concatStrings({
  @required String thisString,
  @required String otherString,
  @required TextDirection thisTextDirection,
  @required TextDirection otherTextDirection
}) {
  if (otherString.isEmpty)
    return thisString;
  String nestedLabel = otherString;
  if (thisTextDirection != otherTextDirection && otherTextDirection != null) {
    switch (otherTextDirection) {
      case TextDirection.rtl:
        nestedLabel = '${Unicode.RLE}$nestedLabel${Unicode.PDF}';
        break;
      case TextDirection.ltr:
        nestedLabel = '${Unicode.LRE}$nestedLabel${Unicode.PDF}';
        break;
    }
  }
  if (thisString.isEmpty)
    return nestedLabel;
  return '$thisString\n$nestedLabel';
}

/// Provides a way to specify the order in which semantic nodes are sorted.
///
/// [SemanticsSortOrder] objects contain a list of sort keys in the order in
/// which they are applied. They are attached to [Semantics] widgets in the
/// widget hierarchy, and are merged with the sort orders of their parent
/// [Semantics] widgets. If [SemanticsSortOrder.discardParentOrder] is set to
/// true, then they will instead ignore the sort order from the parents.
///
/// Keys at the same position in the sort order are compared with each other,
/// and keys which are of different types, or which have different
/// [SemanticSortKey.name] values compare as "equal" so that two different types
/// of keys can co-exist at the same level and not interfere with each other,
/// allowing for sorting into groups.  Keys that evaluate as equal, or when
/// compared with Widgets that don't have [Semantics], fall back to the default
/// upper-start-to-lower-end geometric ordering if a text directionality
/// exists, and they sort from top to bottom followed by child insertion order
/// when no directionality is present.
///
/// Since widgets are globally sorted by their sort key, the order does not have
/// to conform to the widget hierarchy.
///
/// This class takes either `key` or `keys` at construction, but not both. The
/// `key` argument is just shorthand for specifying `<SemanticsSortKey>[key]`
/// for the `keys` argument.
///
/// ## Sample code
///
/// ```dart
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return new Column(
///       children: <Widget>[
///         new Semantics(
///           sortOrder: new SemanticsSortOrder(key: new OrdinalSortKey(2.0)),
///           child: const Text('Label One'),
///         ),
///         new Semantics(
///           sortOrder: new SemanticsSortOrder(key: new OrdinalSortKey(1.0)),
///           child: const Text('Label Two'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// The above will create two [Text] widgets with "Label One" and "Label Two" as
/// their text, but, in accessibility mode, "Label Two" will be traversed first,
/// and "Label One" will be next. Without the sort keys, they would be traversed
/// top to bottom instead.
///
/// See also:
///
///  * [Semantics] for an object that annotates widgets with accessibility
///    semantics.
///  * [SemanticsSortKey] for the base class of the sort keys which
///    [SemanticsSortOrder] manages.
///  * [OrdinalSortKey] for a sort key that sorts using an ordinal.
class SemanticsSortOrder extends Diagnosticable implements Comparable<SemanticsSortOrder> {
  /// Creates an object that describes the sort order for a [Semantics] widget.
  ///
  /// Only one of `key` or `keys` may be specified, but at least one must
  /// be specified. Specifying `key` is a shorthand for specifying
  /// `keys: <SemanticsSortKey>[key]`.
  ///
  /// If [discardParentOrder] is set to true, then the [SemanticsSortOrder.keys]
  /// will _replace_ the list of keys from the parents when merged. Otherwise,
  /// the child's keys are appended at the end of the parent's keys.
  SemanticsSortOrder({
    SemanticsSortKey key,
    List<SemanticsSortKey> keys,
    this.discardParentOrder = false,
  }) : assert(key != null || keys != null, 'One of key or keys must be specified.'),
       assert(key == null || keys == null, 'Only one of key or keys may be specified.'),
       keys = key == null ? keys : <SemanticsSortKey>[key];

  /// Whether or not this order is to replace the keys above it in the
  /// semantics tree, or to be appended to them.
  final bool discardParentOrder;

  /// The keys that should be used to sort this node.
  ///
  /// Typically only one key is provided, using the constructor's `key` argument.
  final List<SemanticsSortKey> keys;

  /// Merges two sort orders by concatenating their sort key lists. If
  /// other.discardParentOrder is true, then other's sort key list replaces
  /// that of the list in this object.
  SemanticsSortOrder merge(SemanticsSortOrder other) {
    if (other == null)
      return this;
    if (other.discardParentOrder) {
      return new SemanticsSortOrder(
        keys: new List<SemanticsSortKey>.from(other.keys),
        discardParentOrder: discardParentOrder,
      );
    }
    return new SemanticsSortOrder(
      keys: new List<SemanticsSortKey>.from(keys)
        ..addAll(other.keys),
      discardParentOrder: discardParentOrder,
    );
  }

  @override
  int compareTo(SemanticsSortOrder other) {
    if (this == other) {
      return 0;
    }
    for (int i = 0; i < keys.length && i < other.keys.length; ++i) {
      final int comparison = keys[i].compareTo(other.keys[i]);
      if (comparison != 0) {
        return comparison;
      }
    }
    // If there are more keys to compare, then assume that the shorter
    // list comes before the longer list.
    return keys.length.compareTo(other.keys.length);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new IterableProperty<SemanticsSortKey>('keys', keys, ifEmpty: null));
    description.add(new FlagProperty(
      'replace',
      value: discardParentOrder,
      defaultValue: false,
      ifTrue: 'replace',
    ));
  }
}

/// Base class for all sort keys for [Semantics] accessibility traversal order
/// sorting.
///
/// If subclasses of this class compare themselves to another subclass of
/// [SemanticsSortKey], they will compare as "equal" so that keys of the same
/// type are ordered only with respect to one another.
///
/// See Also:
///
///  * [SemanticsSortOrder] which manages a list of sort keys.
///  * [OrdinalSortKey] for a sort key that sorts using an ordinal.
abstract class SemanticsSortKey extends Diagnosticable implements Comparable<SemanticsSortKey> {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const SemanticsSortKey({this.name});

  /// An optional name that will make this sort key only order itself
  /// with respect to other sort keys of the same [name], as long as
  /// they are of the same [runtimeType]. If compared with a
  /// [SemanticsSortKey] with a different name or type, they will
  /// compare as "equal".
  final String name;

  @override
  int compareTo(SemanticsSortKey other) {
    if (other.runtimeType != runtimeType || other.name != name)
      return 0;
    return doCompare(other);
  }

  /// The implementation of [compareTo].
  ///
  /// The argument is guaranteed to be of the same type as this object.
  ///
  /// The method should return a negative number if this object comes earlier in
  /// the sort order than the argument; and a positive number if it comes later
  /// in the sort order. Returning zero causes the system to default to
  /// comparing the geometry of the nodes.
  @protected
  int doCompare(covariant SemanticsSortKey other);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new StringProperty('name', name, defaultValue: null));
  }
}

/// A [SemanticsSortKey] that sorts simply based on the `double` value it is
/// given.
///
/// The [OrdinalSortKey] compares itself with other [OrdinalSortKey]s
/// to sort based on the order it is given.
///
/// The ordinal value `order` is typically a whole number, though it can be
/// fractional, e.g. in order to fit between two other consecutive whole
/// numbers. The value must be finite (it cannot be [double.nan],
/// [double.infinity], or [double.negativeInfinity]).
///
/// See also:
///
///  * [SemanticsSortOrder] which manages a list of sort keys.
class OrdinalSortKey extends SemanticsSortKey {
  /// Creates a semantics sort key that uses a [double] as its key value.
  ///
  /// The [order] must be a finite number.
  const OrdinalSortKey(
    this.order, {
    String name,
  }) : assert(order != null),
       assert(order != double.nan),
       assert(order > double.negativeInfinity),
       assert(order < double.infinity),
       super(name: name);

  /// Determines the placement of this key in a sequence of keys that defines
  /// the order in which this node is traversed by the platform's accessibility
  /// services.
  ///
  /// Lower values will be traversed first.
  final double order;

  @override
  int doCompare(OrdinalSortKey other) {
    if (other.order == null || order == null || other.order == order)
      return 0;
    return order.compareTo(other.order);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(new DoubleProperty('order', order, defaultValue: null));
  }
}
