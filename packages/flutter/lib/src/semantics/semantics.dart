// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
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
typedef SemanticsNodeVisitor = bool Function(SemanticsNode node);

/// Signature for [SemanticsAction]s that move the cursor.
///
/// If `extendSelection` is set to true the cursor movement should extend the
/// current selection or (if nothing is currently selected) start a selection.
typedef MoveCursorHandler = void Function(bool extendSelection);

/// Signature for the [SemanticsAction.setSelection] handlers to change the
/// text selection (or re-position the cursor) to `selection`.
typedef SetSelectionHandler = void Function(TextSelection selection);

typedef _SemanticsActionHandler = void Function(dynamic args);

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

/// An identifier of a custom semantics action.
///
/// Custom semantics actions can be provided to make complex user
/// interactions more accessible. For instance, if an application has a
/// drag-and-drop list that requires the user to press and hold an item
/// to move it, users interacting with the application using a hardware
/// switch may have difficulty. This can be made accessible by creating custom
/// actions and pairing them with handlers that move a list item up or down in
/// the list.
///
/// In Android, these actions are presented in the local context menu. In iOS,
/// these are presented in the radial context menu.
///
/// Localization and text direction do not automatically apply to the provided
/// label or hint.
///
/// Instances of this class should either be instantiated with const or
/// new instances cached in static fields.
///
/// See also:
///
///   * [SemanticsProperties], where the handler for a custom action is provided.
@immutable
class CustomSemanticsAction {
  /// Creates a new [CustomSemanticsAction].
  ///
  /// The [label] must not be null or the empty string.
  const CustomSemanticsAction({@required this.label})
    : assert(label != null),
      assert(label != ''),
      hint = null,
      action = null;

  /// Creates a new [CustomSemanticsAction] that overrides a standard semantics
  /// action.
  ///
  /// The [hint] must not be null or the empty string.
  const CustomSemanticsAction.overridingAction({@required this.hint, @required this.action})
    : assert(hint != null),
      assert(hint != ''),
      assert(action != null),
      label = null;

  /// The user readable name of this custom semantics action.
  final String label;

  /// The hint description of this custom semantics action.
  final String hint;

  /// The standard semantics action this action replaces.
  final SemanticsAction action;

  @override
  int get hashCode => ui.hashValues(label, hint, action);

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final CustomSemanticsAction typedOther = other;
    return typedOther.label == label
      && typedOther.hint == hint
      && typedOther.action == action;
  }

  @override
  String toString() {
    return 'CustomSemanticsAction(${_ids[this]}, label:$label, hint:$hint, action:$action)';
  }

  // Logic to assign a unique id to each custom action without requiring
  // user specification.
  static int _nextId = 0;
  static final Map<int, CustomSemanticsAction> _actions = <int, CustomSemanticsAction>{};
  static final Map<CustomSemanticsAction, int> _ids = <CustomSemanticsAction, int>{};

  /// Get the identifier for a given `action`.
  static int getIdentifier(CustomSemanticsAction action) {
    int result = _ids[action];
    if (result == null) {
      result = _nextId++;
      _ids[action] = result;
      _actions[result] = action;
    }
    return result;
  }

  /// Get the `action` for a given identifier.
  static CustomSemanticsAction getAction(int id) {
    return _actions[id];
  }
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
    @required this.rect,
    @required this.textSelection,
    @required this.scrollIndex,
    @required this.scrollChildCount,
    @required this.scrollPosition,
    @required this.scrollExtentMax,
    @required this.scrollExtentMin,
    this.tags,
    this.transform,
    this.customSemanticsActionIds,
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

  /// The currently selected text (or the position of the cursor) within [value]
  /// if this node represents a text field.
  final TextSelection textSelection;

  /// The total number of scrollable children that contribute to semantics.
  ///
  /// If the number of children are unknown or unbounded, this value will be
  /// null.
  final int scrollChildCount;

  /// The index of the first visible semantic child of a scroll node.
  final int scrollIndex;

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

  /// The identifiers for the custom semantics actions and standard action
  /// overrides for this node.
  ///
  /// The list must be sorted in increasing order.
  ///
  /// See also:
  ///
  ///   * [CustomSemanticsAction], for an explanation of custom actions.
  final List<int> customSemanticsActionIds;

  /// Whether [flags] contains the given flag.
  bool hasFlag(SemanticsFlag flag) => (flags & flag.index) != 0;

  /// Whether [actions] contains the given action.
  bool hasAction(SemanticsAction action) => (actions & action.index) != 0;

  @override
  String toStringShort() => '$runtimeType';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Rect>('rect', rect, showName: false));
    properties.add(TransformProperty('transform', transform, showName: false, defaultValue: null));
    final List<String> actionSummary = <String>[];
    for (SemanticsAction action in SemanticsAction.values.values) {
      if ((actions & action.index) != 0)
        actionSummary.add(describeEnum(action));
    }
    final List<String> customSemanticsActionSummary = customSemanticsActionIds
      .map<String>((int actionId) => CustomSemanticsAction.getAction(actionId).label)
      .toList();
    properties.add(IterableProperty<String>('actions', actionSummary, ifEmpty: null));
    properties.add(IterableProperty<String>('customActions', customSemanticsActionSummary, ifEmpty: null));

    final List<String> flagSummary = <String>[];
    for (SemanticsFlag flag in SemanticsFlag.values.values) {
      if ((flags & flag.index) != 0)
        flagSummary.add(describeEnum(flag));
    }
    properties.add(IterableProperty<String>('flags', flagSummary, ifEmpty: null));
    properties.add(StringProperty('label', label, defaultValue: ''));
    properties.add(StringProperty('value', value, defaultValue: ''));
    properties.add(StringProperty('increasedValue', increasedValue, defaultValue: ''));
    properties.add(StringProperty('decreasedValue', decreasedValue, defaultValue: ''));
    properties.add(StringProperty('hint', hint, defaultValue: ''));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    if (textSelection?.isValid == true)
      properties.add(MessageProperty('textSelection', '[${textSelection.start}, ${textSelection.end}]'));
    properties.add(IntProperty('scrollChildren', scrollChildCount, defaultValue: null));
    properties.add(IntProperty('scrollIndex', scrollIndex, defaultValue: null));
    properties.add(DoubleProperty('scrollExtentMin', scrollExtentMin, defaultValue: null));
    properties.add(DoubleProperty('scrollPosition', scrollPosition, defaultValue: null));
    properties.add(DoubleProperty('scrollExtentMax', scrollExtentMax, defaultValue: null));
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
        && typedOther.rect == rect
        && setEquals(typedOther.tags, tags)
        && typedOther.scrollChildCount == scrollChildCount
        && typedOther.scrollIndex == scrollIndex
        && typedOther.textSelection == textSelection
        && typedOther.scrollPosition == scrollPosition
        && typedOther.scrollExtentMax == scrollExtentMax
        && typedOther.scrollExtentMin == scrollExtentMin
        && typedOther.transform == transform
        && _sortedListsEqual(typedOther.customSemanticsActionIds, customSemanticsActionIds);
  }

  @override
  int get hashCode {
    return ui.hashValues(
      flags,
      actions,
      label,
      value,
      increasedValue,
      decreasedValue,
      hint,
      textDirection,
      rect,
      tags,
      textSelection,
      scrollChildCount,
      scrollIndex,
      scrollPosition,
      scrollExtentMax,
      scrollExtentMin,
      transform,
      ui.hashList(customSemanticsActionIds),
    );
  }

  static bool _sortedListsEqual(List<int> left, List<int> right) {
    if (left == null && right == null)
      return true;
    if (left != null && right != null) {
      if (left.length != right.length)
        return false;
      for (int i = 0; i < left.length; i++)
        if (left[i] != right[i])
          return false;
      return true;
    }
    return false;
  }
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

/// Provides hint values which override the default hints on supported
/// platforms.
///
/// On iOS, these values are always ignored.
@immutable
class SemanticsHintOverrides extends DiagnosticableTree {
  /// Creates a semantics hint overrides.
  const SemanticsHintOverrides({
    this.onTapHint,
    this.onLongPressHint,
  }) : assert(onTapHint != ''),
       assert(onLongPressHint != '');

  /// The hint text for a tap action.
  ///
  /// If null, the standard hint is used instead.
  ///
  /// The hint should describe what happens when a tap occurs, not the
  /// manner in which a tap is accomplished.
  ///
  /// Bad: 'Double tap to show movies'.
  /// Good: 'show movies'.
  final String onTapHint;

  /// The hint text for a long press action.
  ///
  /// If null, the standard hint is used instead.
  ///
  /// The hint should describe what happens when a long press occurs, not
  /// the manner in which the long press is accomplished.
  ///
  /// Bad: 'Double tap and hold to show tooltip'.
  /// Good: 'show tooltip'.
  final String onLongPressHint;

  /// Whether there are any non-null hint values.
  bool get isNotEmpty => onTapHint != null || onLongPressHint != null;

  @override
  int get hashCode => ui.hashValues(onTapHint, onLongPressHint);

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final SemanticsHintOverrides typedOther = other;
    return typedOther.onTapHint == onTapHint
      && typedOther.onLongPressHint == onLongPressHint;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('onTapHint', onTapHint, defaultValue: null));
    properties.add(StringProperty('onLongPressHint', onLongPressHint, defaultValue: null));
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
    this.toggled,
    this.button,
    this.header,
    this.textField,
    this.focused,
    this.inMutuallyExclusiveGroup,
    this.hidden,
    this.obscured,
    this.scopesRoute,
    this.namesRoute,
    this.image,
    this.liveRegion,
    this.label,
    this.value,
    this.increasedValue,
    this.decreasedValue,
    this.hint,
    this.hintOverrides,
    this.textDirection,
    this.sortKey,
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
    this.onMoveCursorForwardByWord,
    this.onMoveCursorBackwardByWord,
    this.onSetSelection,
    this.onDidGainAccessibilityFocus,
    this.onDidLoseAccessibilityFocus,
    this.onDismiss,
    this.customSemanticsActions,
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
  ///
  /// This is mutually exclusive with [toggled].
  final bool checked;

  /// If non-null, indicates that this subtree represents a toggle switch
  /// or similar widget with an "on" state, and what its current
  /// state is.
  ///
  /// This is mutually exclusive with [checked].
  final bool toggled;

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

  /// If non-null, whether the node is considered hidden.
  ///
  /// Hidden elements are currently not visible on screen. They may be covered
  /// by other elements or positioned outside of the visible area of a viewport.
  ///
  /// Hidden elements cannot gain accessibility focus though regular touch. The
  /// only way they can be focused is by moving the focus to them via linear
  /// navigation.
  ///
  /// Platforms are free to completely ignore hidden elements and new platforms
  /// are encouraged to do so.
  ///
  /// Instead of marking an element as hidden it should usually be excluded from
  /// the semantics tree altogether. Hidden elements are only included in the
  /// semantics tree to work around platform limitations and they are mainly
  /// used to implement accessibility scrolling on iOS.
  final bool hidden;

  /// If non-null, whether [value] should be obscured.
  ///
  /// This option is usually set in combination with [textField] to indicate
  /// that the text field contains a password (or other sensitive information).
  /// Doing so instructs screen readers to not read out the [value].
  final bool obscured;

  /// If non-null, whether the node corresponds to the root of a subtree for
  /// which a route name should be announced.
  ///
  /// Generally, this is set in combination with [explicitChildNodes], since
  /// nodes with this flag are not considered focusable by Android or iOS.
  ///
  /// See also:
  ///
  ///  * [SemanticsFlag.scopesRoute] for a description of how the announced
  ///    value is selected.
  final bool scopesRoute;

  /// If non-null, whether the node contains the semantic label for a route.
  ///
  /// See also:
  ///
  ///  * [SemanticsFlag.namesRoute] for a description of how the name is used.
  final bool namesRoute;

  /// If non-null, whether the node represents an image.
  ///
  /// See also:
  ///
  ///   * [SemanticsFlag.image], for the flag this setting controls.
  final bool image;

  /// If non-null, whether the node should be considered a live region.
  ///
  /// On Android, when a live region semantics node is first created TalkBack
  /// will make a polite announcement of the current label. This announcement
  /// occurs even if the node is not focused. Subsequent polite announcements
  /// can be made by sending a [UpdateLiveRegionEvent] semantics event. The
  /// announcement will only be made if the node's label has changed since the
  /// last update.
  ///
  /// On iOS, no announcements are made but the node is marked as
  /// `UIAccessibilityTraitUpdatesFrequently`.
  ///
  /// An example of a live region is the [Snackbar] widget. When it appears
  /// on the screen it may be difficult to focus to read the label. A live
  /// region causes an initial polite announcement to be generated
  /// automatically.
  ///
  /// See also:
  ///   * [SemanticsFlag.liveRegion], the semantics flag this setting controls.
  ///   * [SemanticsConfiguration.liveRegion], for a full description of a live region.
  ///   * [UpdateLiveRegionEvent], to trigger a polite announcement of a live region.
  final bool liveRegion;

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

  /// Provides hint values which override the default hints on supported
  /// platforms.
  ///
  /// On Android, If no hint overrides are used then default [hint] will be
  /// combined with the [label]. Otherwise, the [hint] will be ignored as long
  /// as there as at least one non-null hint override.
  ///
  /// On iOS, these are always ignored and the default [hint] is used instead.
  final SemanticsHintOverrides hintOverrides;

  /// The reading direction of the [label], [value], [hint], [increasedValue],
  /// and [decreasedValue].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection textDirection;

  /// Determines the position of this node among its siblings in the traversal
  /// sort order.
  ///
  /// This is used to describe the order in which the semantic node should be
  /// traversed by the accessibility services on the platform (e.g. VoiceOver
  /// on iOS and TalkBack on Android).
  final SemanticsSortKey sortKey;

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

  /// The handler for [SemanticsAction.onMoveCursorForwardByWord].
  ///
  /// This handler is invoked when the user wants to move the cursor in a
  /// text field backward by one word.
  ///
  /// TalkBack users can trigger this by pressing the volume down key while the
  /// input focus is in a text field.
  final MoveCursorHandler onMoveCursorForwardByWord;

  /// The handler for [SemanticsAction.onMoveCursorBackwardByWord].
  ///
  /// This handler is invoked when the user wants to move the cursor in a
  /// text field backward by one word.
  ///
  /// TalkBack users can trigger this by pressing the volume down key while the
  /// input focus is in a text field.
  final MoveCursorHandler onMoveCursorBackwardByWord;

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

  /// The handler for [SemanticsAction.dismiss].
  ///
  /// This is a request to dismiss the currently focused node.
  ///
  /// TalkBack users on Android can trigger this action in the local context
  /// menu, and VoiceOver users on iOS can trigger this action with a standard
  /// gesture or menu option.
  final VoidCallback onDismiss;

  /// A map from each supported [CustomSemanticsAction] to a provided handler.
  ///
  /// The handler associated with each custom action is called whenever a
  /// semantics event of type [SemanticsEvent.customEvent] is received. The
  /// provided argument will be an identifier used to retrieve an instance of
  /// a custom action which can then retrieve the correct handler from this map.
  ///
  /// See also:
  ///
  ///   * [CustomSemanticsAction], for an explanation of custom actions.
  final Map<CustomSemanticsAction, VoidCallback> customSemanticsActions;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('checked', checked, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('selected', selected, defaultValue: null));
    properties.add(StringProperty('label', label, defaultValue: ''));
    properties.add(StringProperty('value', value));
    properties.add(StringProperty('hint', hint));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(DiagnosticsProperty<SemanticsSortKey>('sortKey', sortKey, defaultValue: null));
    properties.add(DiagnosticsProperty<SemanticsHintOverrides>('hintOverrides', hintOverrides));
  }

  @override
  String toStringShort() => '$runtimeType'; // the hashCode isn't important since we're immutable
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

  /// The semantic clip from an ancestor that was applied to this node.
  ///
  /// Expressed in the coordinate system of the node. May be null if no clip has
  /// been applied.
  ///
  /// Descendant [SemanticsNode]s that are positioned outside of this rect will
  /// be excluded from the semantics tree. Descendant [SemanticsNode]s that are
  /// overlapping with this rect, but are outside of [parentPaintClipRect] will
  /// be included in the tree, but they will be marked as hidden because they
  /// are assumed to be not visible on screen.
  ///
  /// If this rect is null, all descendant [SemanticsNode]s outside of
  /// [parentPaintClipRect] will be excluded from the tree.
  ///
  /// If this rect is non-null it has to completely enclose
  /// [parentPaintClipRect]. If [parentPaintClipRect] is null this property is
  /// also null.
  Rect parentSemanticsClipRect;

  /// The paint clip from an ancestor that was applied to this node.
  ///
  /// Expressed in the coordinate system of the node. May be null if no clip has
  /// been applied.
  ///
  /// Descendant [SemanticsNode]s that are positioned outside of this rect will
  /// either be excluded from the semantics tree (if they have no overlap with
  /// [parentSemanticsClipRect]) or they will be included and marked as hidden
  /// (if they are overlapping with [parentSemanticsClipRect]).
  ///
  /// This rect is completely enclosed by [parentSemanticsClipRect].
  ///
  /// If this rect is null [parentSemanticsClipRect] also has to be null.
  Rect parentPaintClipRect;

  /// The index of this node within the parent's list of semantic children.
  ///
  /// This includes all semantic nodes, not just those currently in the
  /// child list. For example, if a scrollable has five children but the first
  /// two are not visible (and thus not included in the list of children), then
  /// the index of the last node will still be 4.
  int indexInParent;

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
        final StringBuffer mutationErrors = StringBuffer();
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
          throw FlutterError(
            'Failed to replace child semantics nodes because the list of `SemanticsNode`s was mutated.\n'
            'Instead of mutating the existing list, create a new list containing the desired `SemanticsNode`s.\n'
            'Error details:\n'
            '$mutationErrors'
          );
        }
      }
      assert(!newChildren.any((SemanticsNode node) => node.isMergedIntoParent) || isPartOfNodeMerging);

      _debugPreviousSnapshot = List<SemanticsNode>.from(newChildren);

      SemanticsNode ancestor = this;
      while (ancestor.parent is SemanticsNode)
        ancestor = ancestor.parent;
      assert(!newChildren.any((SemanticsNode child) => child == ancestor));
      return true;
    }());
    assert(() {
      final Set<SemanticsNode> seenChildren = Set<SemanticsNode>();
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
  /// This function calls visitor for each immediate child until visitor returns
  /// false. Returns true if all the visitor calls returned true, otherwise
  /// returns false.
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
        _sortKey != config._sortKey ||
        _textSelection != config._textSelection ||
        _scrollPosition != config._scrollPosition ||
        _scrollExtentMax != config._scrollExtentMax ||
        _scrollExtentMin != config._scrollExtentMin ||
        _actionsAsBits != config._actionsAsBits ||
        indexInParent != config.indexInParent ||
        _mergeAllDescendantsIntoThisNode != config.isMergingSemanticsOfDescendants;
  }

  // TAGS, LABELS, ACTIONS

  Map<SemanticsAction, _SemanticsActionHandler> _actions = _kEmptyConfig._actions;
  Map<CustomSemanticsAction, VoidCallback> _customSemanticsActions = _kEmptyConfig._customSemanticsActions;

  int _actionsAsBits = _kEmptyConfig._actionsAsBits;

  /// The [SemanticsTag]s this node is tagged with.
  ///
  /// Tags are used during the construction of the semantics tree. They are not
  /// transferred to the engine.
  Set<SemanticsTag> tags;

  /// Whether this node is tagged with `tag`.
  bool isTagged(SemanticsTag tag) => tags != null && tags.contains(tag);

  int _flags = _kEmptyConfig._flags;

  /// Whether this node currently has a given [SemanticsFlag].
  bool hasFlag(SemanticsFlag flag) => _flags & flag.index != 0;

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

  /// Provides hint values which override the default hints on supported
  /// platforms.
  SemanticsHintOverrides get hintOverrides => _hintOverrides;
  SemanticsHintOverrides _hintOverrides;

  /// The reading direction for [label], [value], [hint], [increasedValue], and
  /// [decreasedValue].
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection = _kEmptyConfig.textDirection;

  /// Determines the position of this node among its siblings in the traversal
  /// sort order.
  ///
  /// This is used to describe the order in which the semantic node should be
  /// traversed by the accessibility services on the platform (e.g. VoiceOver
  /// on iOS and TalkBack on Android).
  SemanticsSortKey get sortKey => _sortKey;
  SemanticsSortKey _sortKey;

  /// The currently selected text (or the position of the cursor) within [value]
  /// if this node represents a text field.
  TextSelection get textSelection => _textSelection;
  TextSelection _textSelection;

  /// The total number of scrollable children that contribute to semantics.
  ///
  /// If the number of children are unknown or unbounded, this value will be
  /// null.
  int get scrollChildCount => _scrollChildCount;
  int _scrollChildCount;

  /// The index of the first visible semantic child of a scroll node.
  int get scrollIndex => _scrollIndex;
  int _scrollIndex;

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

  static final SemanticsConfiguration _kEmptyConfig = SemanticsConfiguration();

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
    _hintOverrides = config.hintOverrides;
    _flags = config._flags;
    _textDirection = config.textDirection;
    _sortKey = config.sortKey;
    _actions = Map<SemanticsAction, _SemanticsActionHandler>.from(config._actions);
    _customSemanticsActions = Map<CustomSemanticsAction, VoidCallback>.from(config._customSemanticsActions);
    _actionsAsBits = config._actionsAsBits;
    _textSelection = config._textSelection;
    _scrollPosition = config._scrollPosition;
    _scrollExtentMax = config._scrollExtentMax;
    _scrollExtentMin = config._scrollExtentMin;
    _mergeAllDescendantsIntoThisNode = config.isMergingSemanticsOfDescendants;
    _scrollChildCount = config.scrollChildCount;
    _scrollIndex = config.scrollIndex;
    indexInParent = config.indexInParent;
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
    Set<SemanticsTag> mergedTags = tags == null ? null : Set<SemanticsTag>.from(tags);
    TextSelection textSelection = _textSelection;
    int scrollChildCount = _scrollChildCount;
    int scrollIndex = _scrollIndex;
    double scrollPosition = _scrollPosition;
    double scrollExtentMax = _scrollExtentMax;
    double scrollExtentMin = _scrollExtentMin;
    final Set<int> customSemanticsActionIds = Set<int>();
    for (CustomSemanticsAction action in _customSemanticsActions.keys)
      customSemanticsActionIds.add(CustomSemanticsAction.getIdentifier(action));
    if (hintOverrides != null) {
      if (hintOverrides.onTapHint != null) {
        final CustomSemanticsAction action = CustomSemanticsAction.overridingAction(
          hint: hintOverrides.onTapHint,
          action: SemanticsAction.tap,
        );
        customSemanticsActionIds.add(CustomSemanticsAction.getIdentifier(action));
      }
      if (hintOverrides.onLongPressHint != null) {
        final CustomSemanticsAction action = CustomSemanticsAction.overridingAction(
          hint: hintOverrides.onLongPressHint,
          action: SemanticsAction.longPress,
        );
        customSemanticsActionIds.add(CustomSemanticsAction.getIdentifier(action));
      }
    }

    if (mergeAllDescendantsIntoThisNode) {
      _visitDescendants((SemanticsNode node) {
        assert(node.isMergedIntoParent);
        flags |= node._flags;
        actions |= node._actionsAsBits;
        textDirection ??= node._textDirection;
        textSelection ??= node._textSelection;
        scrollChildCount ??= node._scrollChildCount;
        scrollIndex ??= node._scrollIndex;
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
          mergedTags ??= Set<SemanticsTag>();
          mergedTags.addAll(node.tags);
        }
        if (node._customSemanticsActions != null) {
          for (CustomSemanticsAction action in _customSemanticsActions.keys)
            customSemanticsActionIds.add(CustomSemanticsAction.getIdentifier(action));
        }
        if (node.hintOverrides != null) {
          if (node.hintOverrides.onTapHint != null) {
            final CustomSemanticsAction action = CustomSemanticsAction.overridingAction(
              hint: node.hintOverrides.onTapHint,
              action: SemanticsAction.tap,
            );
            customSemanticsActionIds.add(CustomSemanticsAction.getIdentifier(action));
          }
          if (node.hintOverrides.onLongPressHint != null) {
            final CustomSemanticsAction action = CustomSemanticsAction.overridingAction(
              hint: node.hintOverrides.onLongPressHint,
              action: SemanticsAction.longPress,
            );
            customSemanticsActionIds.add(CustomSemanticsAction.getIdentifier(action));
          }
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

    return SemanticsData(
      flags: flags,
      actions: actions,
      label: label,
      value: value,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      hint: hint,
      textDirection: textDirection,
      rect: rect,
      transform: transform,
      tags: mergedTags,
      textSelection: textSelection,
      scrollChildCount: scrollChildCount,
      scrollIndex: scrollIndex,
      scrollPosition: scrollPosition,
      scrollExtentMax: scrollExtentMax,
      scrollExtentMin: scrollExtentMin,
      customSemanticsActionIds: customSemanticsActionIds.toList()..sort(),
    );
  }

  static Float64List _initIdentityTransform() {
    return Matrix4.identity().storage;
  }

  static final Int32List _kEmptyChildList = Int32List(0);
  static final Int32List _kEmptyCustomSemanticsActionsList = Int32List(0);
  static final Float64List _kIdentityTransform = _initIdentityTransform();

  void _addToUpdate(ui.SemanticsUpdateBuilder builder, Set<int> customSemanticsActionIdsUpdate) {
    assert(_dirty);
    final SemanticsData data = getSemanticsData();
    Int32List childrenInTraversalOrder;
    Int32List childrenInHitTestOrder;
    if (!hasChildren || mergeAllDescendantsIntoThisNode) {
      childrenInTraversalOrder = _kEmptyChildList;
      childrenInHitTestOrder = _kEmptyChildList;
    } else {
      final int childCount = _children.length;
      final List<SemanticsNode> sortedChildren = _childrenInTraversalOrder();
      childrenInTraversalOrder = Int32List(childCount);
      for (int i = 0; i < childCount; i += 1) {
        childrenInTraversalOrder[i] = sortedChildren[i].id;
      }
      // _children is sorted in paint order, so we invert it to get the hit test
      // order.
      childrenInHitTestOrder = Int32List(childCount);
      for (int i = childCount - 1; i >= 0; i -= 1) {
        childrenInHitTestOrder[i] = _children[childCount - i - 1].id;
      }
    }
    Int32List customSemanticsActionIds;
    if (data.customSemanticsActionIds?.isNotEmpty == true) {
      customSemanticsActionIds = Int32List(data.customSemanticsActionIds.length);
      for (int i = 0; i < data.customSemanticsActionIds.length; i++) {
        customSemanticsActionIds[i] = data.customSemanticsActionIds[i];
        customSemanticsActionIdsUpdate.add(data.customSemanticsActionIds[i]);
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
      textSelectionBase: data.textSelection != null ? data.textSelection.baseOffset : -1,
      textSelectionExtent: data.textSelection != null ? data.textSelection.extentOffset : -1,
      scrollChildren: data.scrollChildCount != null ? data.scrollChildCount : 0,
      scrollIndex: data.scrollIndex != null ? data.scrollIndex : 0 ,
      scrollPosition: data.scrollPosition != null ? data.scrollPosition : double.nan,
      scrollExtentMax: data.scrollExtentMax != null ? data.scrollExtentMax : double.nan,
      scrollExtentMin: data.scrollExtentMin != null ? data.scrollExtentMin : double.nan,
      transform: data.transform?.storage ?? _kIdentityTransform,
      childrenInTraversalOrder: childrenInTraversalOrder,
      childrenInHitTestOrder: childrenInHitTestOrder,
      additionalActions: customSemanticsActionIds ?? _kEmptyCustomSemanticsActionsList,
    );
    _dirty = false;
  }

  /// Builds a new list made of [_children] sorted in semantic traversal order.
  List<SemanticsNode> _childrenInTraversalOrder() {
    TextDirection inheritedTextDirection = textDirection;
    SemanticsNode ancestor = parent;
    while (inheritedTextDirection == null && ancestor != null) {
      inheritedTextDirection = ancestor.textDirection;
      ancestor = ancestor.parent;
    }

    List<SemanticsNode> childrenInDefaultOrder;
    if (inheritedTextDirection != null) {
      childrenInDefaultOrder = _childrenInDefaultOrder(_children, inheritedTextDirection);
    } else {
      // In the absence of text direction default to paint order.
      childrenInDefaultOrder = _children;
    }

    // List.sort does not guarantee stable sort order. Therefore, children are
    // first partitioned into groups that have compatible sort keys, i.e. keys
    // in the same group can be compared to each other. These groups stay in
    // the same place. Only children within the same group are sorted.
    final List<_TraversalSortNode> everythingSorted = <_TraversalSortNode>[];
    final List<_TraversalSortNode> sortNodes = <_TraversalSortNode>[];
    SemanticsSortKey lastSortKey;
    for (int position = 0; position < childrenInDefaultOrder.length; position += 1) {
      final SemanticsNode child = childrenInDefaultOrder[position];
      final SemanticsSortKey sortKey = child.sortKey;
      lastSortKey = position > 0
          ? childrenInDefaultOrder[position - 1].sortKey
          : null;
      final bool isCompatibleWithPreviousSortKey = position == 0 ||
          sortKey.runtimeType == lastSortKey.runtimeType &&
          (sortKey == null || sortKey.name == lastSortKey.name);
      if (!isCompatibleWithPreviousSortKey && sortNodes.isNotEmpty) {
        // Do not sort groups with null sort keys. List.sort does not guarantee
        // a stable sort order.
        if (lastSortKey != null) {
          sortNodes.sort();
        }
        everythingSorted.addAll(sortNodes);
        sortNodes.clear();
      }

      sortNodes.add(_TraversalSortNode(
        node: child,
        sortKey: sortKey,
        position: position,
      ));
    }

    // Do not sort groups with null sort keys. List.sort does not guarantee
    // a stable sort order.
    if (lastSortKey != null) {
      sortNodes.sort();
    }
    everythingSorted.addAll(sortNodes);

    return everythingSorted
      .map<SemanticsNode>((_TraversalSortNode sortNode) => sortNode.node)
      .toList();
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
      properties.add(FlagProperty('inDirtyNodes', value: inDirtyNodes, ifTrue: 'dirty', ifFalse: 'STALE'));
      hideOwner = inDirtyNodes;
    }
    properties.add(DiagnosticsProperty<SemanticsOwner>('owner', owner, level: hideOwner ? DiagnosticLevel.hidden : DiagnosticLevel.info));
    properties.add(FlagProperty('isMergedIntoParent', value: isMergedIntoParent, ifTrue: 'merged up ⬆️'));
    properties.add(FlagProperty('mergeAllDescendantsIntoThisNode', value: mergeAllDescendantsIntoThisNode, ifTrue: 'merge boundary ⛔️'));
    final Offset offset = transform != null ? MatrixUtils.getAsTranslation(transform) : null;
    if (offset != null) {
      properties.add(DiagnosticsProperty<Rect>('rect', rect.shift(offset), showName: false));
    } else {
      final double scale = transform != null ? MatrixUtils.getAsScale(transform) : null;
      String description;
      if (scale != null) {
        description = '$rect scaled by ${scale.toStringAsFixed(1)}x';
      } else if (transform != null && !MatrixUtils.isIdentity(transform)) {
        final String matrix = transform.toString().split('\n').take(4).map<String>((String line) => line.substring(4)).join('; ');
        description = '$rect with transform [$matrix]';
      }
      properties.add(DiagnosticsProperty<Rect>('rect', rect, description: description, showName: false));
    }
    final List<String> actions = _actions.keys.map<String>((SemanticsAction action) => describeEnum(action)).toList()..sort();
    final List<String> customSemanticsActions = _customSemanticsActions.keys
      .map<String>((CustomSemanticsAction action) => action.label)
      .toList();
    properties.add(IterableProperty<String>('actions', actions, ifEmpty: null));
    properties.add(IterableProperty<String>('customActions', customSemanticsActions, ifEmpty: null));
    final List<String> flags = SemanticsFlag.values.values.where((SemanticsFlag flag) => hasFlag(flag)).map((SemanticsFlag flag) => flag.toString().substring('SemanticsFlag.'.length)).toList();
    properties.add(IterableProperty<String>('flags', flags, ifEmpty: null));
    properties.add(FlagProperty('isInvisible', value: isInvisible, ifTrue: 'invisible'));
    properties.add(FlagProperty('isHidden', value: hasFlag(SemanticsFlag.isHidden), ifTrue: 'HIDDEN'));
    properties.add(StringProperty('label', _label, defaultValue: ''));
    properties.add(StringProperty('value', _value, defaultValue: ''));
    properties.add(StringProperty('increasedValue', _increasedValue, defaultValue: ''));
    properties.add(StringProperty('decreasedValue', _decreasedValue, defaultValue: ''));
    properties.add(StringProperty('hint', _hint, defaultValue: ''));
    properties.add(EnumProperty<TextDirection>('textDirection', _textDirection, defaultValue: null));
    properties.add(DiagnosticsProperty<SemanticsSortKey>('sortKey', sortKey, defaultValue: null));
    if (_textSelection?.isValid == true)
      properties.add(MessageProperty('text selection', '[${_textSelection.start}, ${_textSelection.end}]'));
    properties.add(IntProperty('scrollChildren', scrollChildCount, defaultValue: null));
    properties.add(IntProperty('scrollIndex', scrollIndex, defaultValue: null));
    properties.add(DoubleProperty('scrollExtentMin', scrollExtentMin, defaultValue: null));
    properties.add(DoubleProperty('scrollPosition', scrollPosition, defaultValue: null));
    properties.add(DoubleProperty('scrollExtentMax', scrollExtentMax, defaultValue: null));
  }

  /// Returns a string representation of this node and its descendants.
  ///
  /// The order in which the children of the [SemanticsNode] will be printed is
  /// controlled by the [childOrder] parameter.
  @override
  String toStringDeep({
    String prefixLineOne = '',
    String prefixOtherLines,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
    DebugSemanticsDumpOrder childOrder = DebugSemanticsDumpOrder.traversalOrder,
  }) {
    assert(childOrder != null);
    return toDiagnosticsNode(childOrder: childOrder).toStringDeep(prefixLineOne: prefixLineOne, prefixOtherLines: prefixOtherLines, minLevel: minLevel);
  }

  @override
  DiagnosticsNode toDiagnosticsNode({
    String name,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.sparse,
    DebugSemanticsDumpOrder childOrder = DebugSemanticsDumpOrder.traversalOrder,
  }) {
    return _SemanticsDiagnosticableNode(
      name: name,
      value: this,
      style: style,
      childOrder: childOrder,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren({ DebugSemanticsDumpOrder childOrder = DebugSemanticsDumpOrder.inverseHitTest }) {
    return debugListChildrenInOrder(childOrder)
      .map<DiagnosticsNode>((SemanticsNode node) => node.toDiagnosticsNode(childOrder: childOrder))
      .toList();
  }

  /// Returns the list of direct children of this node in the specified order.
  List<SemanticsNode> debugListChildrenInOrder(DebugSemanticsDumpOrder childOrder) {
    assert(childOrder != null);
    if (_children == null)
      return const <SemanticsNode>[];

    switch (childOrder) {
      case DebugSemanticsDumpOrder.inverseHitTest:
        return _children;
      case DebugSemanticsDumpOrder.traversalOrder:
        return _childrenInTraversalOrder();
    }
    assert(false);
    return null;
  }
}

/// An edge of a box, such as top, bottom, left or right, used to compute
/// [SemanticsNode]s that overlap vertically or horizontally.
///
/// For computing horizontal overlap in an LTR setting we create two [_BoxEdge]
/// objects for each [SemanticsNode]: one representing the left edge (marked
/// with [isLeadingEdge] equal to true) and one for the right edge (with [isLeadingEdge]
/// equal to false). Similarly, for vertical overlap we also create two objects
/// for each [SemanticsNode], one for the top and one for the bottom edge.
class _BoxEdge implements Comparable<_BoxEdge> {
  _BoxEdge({
    @required this.isLeadingEdge,
    @required this.offset,
    @required this.node,
  }) : assert(isLeadingEdge != null),
       assert(offset != null),
       assert(node != null);

  /// True if the edge comes before the seconds edge along the traversal
  /// direction, and false otherwise.
  ///
  /// This field is never null.
  ///
  /// For example, in LTR traversal the left edge's [isLeadingEdge] is set to true,
  /// the right edge's [isLeadingEdge] is set to false. When considering vertical
  /// ordering of boxes, the top edge is the start edge, and the bottom edge is
  /// the end edge.
  final bool isLeadingEdge;

  /// The offset from the start edge of the parent [SemanticsNode] in the
  /// direction of the traversal.
  final double offset;

  /// The node whom this edge belongs.
  final SemanticsNode node;

  @override
  int compareTo(_BoxEdge other) {
    return (offset - other.offset).sign.toInt();
  }
}

/// A group of [nodes] that are disjoint vertically or horizontally from other
/// nodes that share the same [SemanticsNode] parent.
///
/// The [nodes] are sorted among each other separately from other nodes.
class _SemanticsSortGroup extends Comparable<_SemanticsSortGroup> {
  _SemanticsSortGroup({
    @required this.startOffset,
    @required this.textDirection,
  }) : assert(startOffset != null);

  /// The offset from the start edge of the parent [SemanticsNode] in the
  /// direction of the traversal.
  ///
  /// This value is equal to the [_BoxEdge.offset] of the first node in the
  /// [nodes] list being considered.
  final double startOffset;

  final TextDirection textDirection;

  /// The nodes that are sorted among each other.
  final List<SemanticsNode> nodes = <SemanticsNode>[];

  @override
  int compareTo(_SemanticsSortGroup other) {
    return (startOffset - other.startOffset).sign.toInt();
  }

  /// Sorts this group assuming that [nodes] belong to the same vertical group.
  ///
  /// This method breaks up this group into horizontal [_SemanticsSortGroup]s
  /// then sorts them using [sortedWithinKnot].
  List<SemanticsNode> sortedWithinVerticalGroup() {
    final List<_BoxEdge> edges = <_BoxEdge>[];
    for (SemanticsNode child in nodes) {
      // Using a small delta to shrink child rects removes overlapping cases.
      final Rect childRect = child.rect.deflate(0.1);
      edges.add(_BoxEdge(
        isLeadingEdge: true,
        offset: _pointInParentCoordinates(child, childRect.topLeft).dx,
        node: child,
      ));
      edges.add(_BoxEdge(
        isLeadingEdge: false,
        offset: _pointInParentCoordinates(child, childRect.bottomRight).dx,
        node: child,
      ));
    }
    edges.sort();

    List<_SemanticsSortGroup> horizontalGroups = <_SemanticsSortGroup>[];
    _SemanticsSortGroup group;
    int depth = 0;
    for (_BoxEdge edge in edges) {
      if (edge.isLeadingEdge) {
        depth += 1;
        group ??= _SemanticsSortGroup(
          startOffset: edge.offset,
          textDirection: textDirection,
        );
        group.nodes.add(edge.node);
      } else {
        depth -= 1;
      }
      if (depth == 0) {
        horizontalGroups.add(group);
        group = null;
      }
    }
    horizontalGroups.sort();

    if (textDirection == TextDirection.rtl) {
      horizontalGroups = horizontalGroups.reversed.toList();
    }

    final List<SemanticsNode> result = <SemanticsNode>[];
    for (_SemanticsSortGroup group in horizontalGroups) {
      final List<SemanticsNode> sortedKnotNodes = group.sortedWithinKnot();
      result.addAll(sortedKnotNodes);
    }
    return result;
  }

  /// Sorts [nodes] where nodes intersect both vertically and horizontally.
  ///
  /// In the special case when [nodes] contains one or less nodes, this method
  /// returns [nodes] unchanged.
  ///
  /// This method constructs a graph, where vertices are [SemanticsNode]s and
  /// edges are "traversed before" relation between pairs of nodes. The sort
  /// order is the topological sorting of the graph, with the original order of
  /// [nodes] used as the tie breaker.
  ///
  /// Whether a node is traversed before another node is determined by the
  /// vector that connects the two nodes' centers. If the vector "points to the
  /// right or down", defined as the [Offset.direction] being between `-pi/4`
  /// and `3*pi/4`), then the semantics node whose center is at the end of the
  /// vector is said to be traversed after.
  List<SemanticsNode> sortedWithinKnot() {
    if (nodes.length <= 1) {
      // Trivial knot. Nothing to do.
      return nodes;
    }
    final Map<int, SemanticsNode> nodeMap = <int, SemanticsNode>{};
    final Map<int, int> edges = <int, int>{};
    for (SemanticsNode node in nodes) {
      nodeMap[node.id] = node;
      final Offset center = _pointInParentCoordinates(node, node.rect.center);
      for (SemanticsNode nextNode in nodes) {
        if (identical(node, nextNode) || edges[nextNode.id] == node.id) {
          // Skip self or when we've already established that the next node
          // points to current node.
          continue;
        }

        final Offset nextCenter = _pointInParentCoordinates(nextNode, nextNode.rect.center);
        final Offset centerDelta = nextCenter - center;
        // When centers coincide, direction is 0.0.
        final double direction = centerDelta.direction;
        final bool isLtrAndForward = textDirection == TextDirection.ltr &&
            -math.pi / 4 < direction && direction < 3 * math.pi / 4;
        final bool isRtlAndForward = textDirection == TextDirection.rtl &&
            (direction < -3 * math.pi / 4 || direction > 3 * math.pi / 4);
        if (isLtrAndForward || isRtlAndForward) {
          edges[node.id] = nextNode.id;
        }
      }
    }

    final List<int> sortedIds = <int>[];
    final Set<int> visitedIds = Set<int>();
    final List<SemanticsNode> startNodes = nodes.toList()..sort((SemanticsNode a, SemanticsNode b) {
      final Offset aTopLeft = _pointInParentCoordinates(a, a.rect.topLeft);
      final Offset bTopLeft = _pointInParentCoordinates(b, b.rect.topLeft);
      final int verticalDiff = aTopLeft.dy.compareTo(bTopLeft.dy);
      if (verticalDiff != 0) {
        return -verticalDiff;
      }
      return -aTopLeft.dx.compareTo(bTopLeft.dx);
    });

    void search(int id) {
      if (visitedIds.contains(id)) {
        return;
      }
      visitedIds.add(id);
      if (edges.containsKey(id)) {
        search(edges[id]);
      }
      sortedIds.add(id);
    }

    startNodes.map<int>((SemanticsNode node) => node.id).forEach(search);
    return sortedIds.map<SemanticsNode>((int id) => nodeMap[id]).toList().reversed.toList();
  }
}

/// Converts `point` to the `node`'s parent's coordinate system.
Offset _pointInParentCoordinates(SemanticsNode node, Offset point) {
  if (node.transform == null) {
    return point;
  }
  final Vector3 vector = Vector3(point.dx, point.dy, 0.0);
  node.transform.transform3(vector);
  return Offset(vector.x, vector.y);
}

/// Sorts `children` using the default sorting algorithm, and returns them as a
/// new list.
///
/// The algorithm first breaks up children into groups such that no two nodes
/// from different groups overlap vertically. These groups are sorted vertically
/// according to their [_SemanticsSortGroup.startOffset].
///
/// Within each group, the nodes are sorted using
/// [_SemanticsSortGroup.sortedWithinVerticalGroup].
///
/// For an illustration of the algorithm see http://bit.ly/flutter-default-traversal.
List<SemanticsNode> _childrenInDefaultOrder(List<SemanticsNode> children, TextDirection textDirection) {
  final List<_BoxEdge> edges = <_BoxEdge>[];
  for (SemanticsNode child in children) {
    // Using a small delta to shrink child rects removes overlapping cases.
    final Rect childRect = child.rect.deflate(0.1);
    edges.add(_BoxEdge(
      isLeadingEdge: true,
      offset: _pointInParentCoordinates(child, childRect.topLeft).dy,
      node: child,
    ));
    edges.add(_BoxEdge(
      isLeadingEdge: false,
      offset: _pointInParentCoordinates(child, childRect.bottomRight).dy,
      node: child,
    ));
  }
  edges.sort();

  final List<_SemanticsSortGroup> verticalGroups = <_SemanticsSortGroup>[];
  _SemanticsSortGroup group;
  int depth = 0;
  for (_BoxEdge edge in edges) {
    if (edge.isLeadingEdge) {
      depth += 1;
      group ??= _SemanticsSortGroup(
        startOffset: edge.offset,
        textDirection: textDirection,
      );
      group.nodes.add(edge.node);
    } else {
      depth -= 1;
    }
    if (depth == 0) {
      verticalGroups.add(group);
      group = null;
    }
  }
  verticalGroups.sort();

  final List<SemanticsNode> result = <SemanticsNode>[];
  for (_SemanticsSortGroup group in verticalGroups) {
    final List<SemanticsNode> sortedGroupNodes = group.sortedWithinVerticalGroup();
    result.addAll(sortedGroupNodes);
  }
  return result;
}

/// The implementation of [Comparable] that implements the ordering of
/// [SemanticsNode]s in the accessibility traversal.
///
/// [SemanticsNode]s are sorted prior to sending them to the engine side.
///
/// This implementation considers a [node]'s [sortKey] and its position within
/// the list of its siblings. [sortKey] takes precedence over position.
class _TraversalSortNode implements Comparable<_TraversalSortNode> {
  _TraversalSortNode({
    @required this.node,
    this.sortKey,
    @required this.position,
  })
    : assert(node != null),
      assert(position != null);

  /// The node whose position this sort node determines.
  final SemanticsNode node;

  /// Determines the position of this node among its siblings.
  ///
  /// Sort keys take precedence over other attributes, such as
  /// [position].
  final SemanticsSortKey sortKey;

  /// Position within the list of siblings as determined by the default sort
  /// order.
  final int position;

  @override
  int compareTo(_TraversalSortNode other) {
    if (sortKey == null || other?.sortKey == null) {
      return position - other.position;
    }
    return sortKey.compareTo(other.sortKey);
  }
}

/// Owns [SemanticsNode] objects and notifies listeners of changes to the
/// render tree semantics.
///
/// To listen for semantic updates, call [PipelineOwner.ensureSemantics] to
/// obtain a [SemanticsHandle]. This will create a [SemanticsOwner] if
/// necessary.
class SemanticsOwner extends ChangeNotifier {
  final Set<SemanticsNode> _dirtyNodes = Set<SemanticsNode>();
  final Map<int, SemanticsNode> _nodes = <int, SemanticsNode>{};
  final Set<SemanticsNode> _detachedNodes = Set<SemanticsNode>();
  final Map<int, CustomSemanticsAction> _actions = <int, CustomSemanticsAction>{};

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

  /// Update the semantics using [Window.updateSemantics].
  void sendSemanticsUpdate() {
    if (_dirtyNodes.isEmpty)
      return;
    final Set<int> customSemanticsActionIds = Set<int>();
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
    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
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
        node._addToUpdate(builder, customSemanticsActionIds);
    }
    _dirtyNodes.clear();
    for (int actionId in customSemanticsActionIds) {
      final CustomSemanticsAction action = CustomSemanticsAction.getAction(actionId);
      builder.updateCustomAction(id: actionId, label: action.label, hint: action.hint, overrideId: action.action?.index ?? -1);
    }
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
      final Matrix4 inverse = Matrix4.identity();
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

  /// The handler for [SemanticsAction.dismiss].
  ///
  /// This is a request to dismiss the currently focused node.
  ///
  /// TalkBack users on Android can trigger this action in the local context
  /// menu, and VoiceOver users on iOS can trigger this action with a standard
  /// gesture or menu option.
  VoidCallback get onDismiss => _onDismiss;
  VoidCallback _onDismiss;
  set onDismiss(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.dismiss, value);
    _onDismiss = value;
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

  /// The handler for [SemanticsAction.onMoveCursorForwardByWord].
  ///
  /// This handler is invoked when the user wants to move the cursor in a
  /// text field backward by one word.
  ///
  /// TalkBack users can trigger this by pressing the volume down key while the
  /// input focus is in a text field.
  MoveCursorHandler get onMoveCursorForwardByWord => _onMoveCursorForwardByWord;
  MoveCursorHandler _onMoveCursorForwardByWord;
  set onMoveCursorForwardByWord(MoveCursorHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.moveCursorForwardByWord, (dynamic args) {
      final bool extentSelection = args;
      assert(extentSelection != null);
      value(extentSelection);
    });
    _onMoveCursorForwardByCharacter = value;
  }

  /// The handler for [SemanticsAction.onMoveCursorBackwardByWord].
  ///
  /// This handler is invoked when the user wants to move the cursor in a
  /// text field backward by one word.
  ///
  /// TalkBack users can trigger this by pressing the volume down key while the
  /// input focus is in a text field.
  MoveCursorHandler get onMoveCursorBackwardByWord => _onMoveCursorBackwardByWord;
  MoveCursorHandler _onMoveCursorBackwardByWord;
  set onMoveCursorBackwardByWord(MoveCursorHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.moveCursorBackwardByWord, (dynamic args) {
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
      value(TextSelection(
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

  /// Determines the position of this node among its siblings in the traversal
  /// sort order.
  ///
  /// This is used to describe the order in which the semantic node should be
  /// traversed by the accessibility services on the platform (e.g. VoiceOver
  /// on iOS and TalkBack on Android).
  ///
  /// Whether this sort key has an effect on the [SemanticsNode] sort order is
  /// subject to how this configuration is used. For example, the [absorb]
  /// method may decide to not use this key when it combines multiple
  /// [SemanticsConfiguration] objects.
  SemanticsSortKey get sortKey => _sortKey;
  SemanticsSortKey _sortKey;
  set sortKey(SemanticsSortKey value) {
    assert(value != null);
    _sortKey = value;
    _hasBeenAnnotated = true;
  }

  /// The index of this node within the parent's list of semantic children.
  ///
  /// This includes all semantic nodes, not just those currently in the
  /// child list. For example, if a scrollable has five children but the first
  /// two are not visible (and thus not included in the list of children), then
  /// the index of the last node will still be 4.
  int get indexInParent => _indexInParent;
  int _indexInParent;
  set indexInParent(int value) {
    _indexInParent = value;
    _hasBeenAnnotated = true;
  }

  /// The total number of scrollable children that contribute to semantics.
  ///
  /// If the number of children are unknown or unbounded, this value will be
  /// null.
  int get scrollChildCount => _scrollChildCount;
  int _scrollChildCount;
  set scrollChildCount(int value) {
    if (value == scrollChildCount)
      return;
    _scrollChildCount = value;
    _hasBeenAnnotated = true;
  }

  /// The index of the first visible scrollable child that contributes to
  /// semantics.
  int get scrollIndex => _scrollIndex;
  int _scrollIndex;
  set scrollIndex(int value) {
    if (value == scrollIndex)
      return;
    _scrollIndex = value;
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

  /// The handlers for each supported [CustomSemanticsAction].
  ///
  /// Whenever a custom accessibility action is added to a node, the action
  /// [SemanticAction.customAction] is automatically added. A handler is
  /// created which uses the passed argument to lookup the custom action
  /// handler from this map and invoke it, if present.
  Map<CustomSemanticsAction, VoidCallback> get customSemanticsActions => _customSemanticsActions;
  Map<CustomSemanticsAction, VoidCallback> _customSemanticsActions = <CustomSemanticsAction, VoidCallback>{};
  set customSemanticsActions(Map<CustomSemanticsAction, VoidCallback> value) {
    _hasBeenAnnotated = true;
    _actionsAsBits |= SemanticsAction.customAction.index;
    _customSemanticsActions = value;
    _actions[SemanticsAction.customAction] = _onCustomSemanticsAction;
  }

  void _onCustomSemanticsAction(dynamic args) {
    final CustomSemanticsAction action = CustomSemanticsAction.getAction(args);
    if (action == null)
      return;
    final VoidCallback callback = _customSemanticsActions[action];
    if (callback != null)
      callback();
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

  /// Provides hint values which override the default hints on supported
  /// platforms.
  SemanticsHintOverrides get hintOverrides => _hintOverrides;
  SemanticsHintOverrides _hintOverrides;
  set hintOverrides(SemanticsHintOverrides value) {
    if (value == null)
      return;
    _hintOverrides = value;
    _hasBeenAnnotated = true;
  }

  /// Whether the semantics node is the root of a subtree for which values
  /// should be announced.
  ///
  /// See also:
  ///  * [SemanticsFlag.scopesRoute], for a full description of route scoping.
  bool get scopesRoute => _hasFlag(SemanticsFlag.scopesRoute);
  set scopesRoute(bool value) {
    _setFlag(SemanticsFlag.scopesRoute, value);
  }

  /// Whether the semantics node contains the label of a route.
  ///
  /// See also:
  ///  * [SemanticsFlag.namesRoute], for a full description of route naming.
  bool get namesRoute => _hasFlag(SemanticsFlag.namesRoute);
  set namesRoute(bool value) {
    _setFlag(SemanticsFlag.namesRoute, value);
  }

  /// Whether the semantics node represents an image.
  bool get isImage => _hasFlag(SemanticsFlag.isImage);
  set isImage(bool value) {
    _setFlag(SemanticsFlag.isImage, value);
  }

  /// Whether the semantics node is a live region.
  ///
  /// On Android, when a live region semantics node is first created TalkBack
  /// will make a polite announcement of the current label. This announcement
  /// occurs even if the node is not focused. Subsequent polite announcements
  /// can be made by sending a [UpdateLiveRegionEvent] semantics event. The
  /// announcement will only be made if the node's label has changed since the
  /// last update.
  ///
  /// An example of a live region is the [Snackbar] widget. When it appears
  /// on the screen it may be difficult to focus to read the label. A live
  /// region causes an initial polite announcement to be generated
  /// automatically.
  ///
  /// See also:
  ///
  ///   * [SemanticsFlag.isLiveRegion], the semantics flag that this setting controls.
  bool get liveRegion => _hasFlag(SemanticsFlag.isLiveRegion);
  set liveRegion(bool value) {
    _setFlag(SemanticsFlag.isLiveRegion, value);
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
  ///
  /// This is different from having accessibility focus. The element that is
  /// accessibility focused may or may not be selected; e.g. a [ListTile] can have
  /// accessibility focus but have its [ListTile.selected] property set to false,
  /// in which case it will not be flagged as selected.
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
  ///
  /// This property does not control whether semantics are enabled. If you wish to
  /// disable semantics for a particular widget, you should use an [ExcludeSemantics]
  /// widget.
  bool get isEnabled => _hasFlag(SemanticsFlag.hasEnabledState) ? _hasFlag(SemanticsFlag.isEnabled) : null;
  set isEnabled(bool value) {
    _setFlag(SemanticsFlag.hasEnabledState, true);
    _setFlag(SemanticsFlag.isEnabled, value);
  }

  /// If this node has Boolean state that can be controlled by the user, whether
  /// that state is checked or unchecked, corresponding to true and false,
  /// respectively.
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

  /// If this node has Boolean state that can be controlled by the user, whether
  /// that state is on or off, corresponding to true and false, respectively.
  ///
  /// Do not call the setter for this field if the owning [RenderObject] doesn't
  /// have on/off state that can be controlled by the user.
  ///
  /// The getter returns null if the owning [RenderObject] does not have
  /// on/off state.
  bool get isToggled => _hasFlag(SemanticsFlag.hasToggledState) ? _hasFlag(SemanticsFlag.isToggled) : null;
  set isToggled(bool value) {
    _setFlag(SemanticsFlag.hasToggledState, true);
    _setFlag(SemanticsFlag.isToggled, value);
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

  /// Whether the owning [RenderObject] is considered hidden.
  ///
  /// Hidden elements are currently not visible on screen. They may be covered
  /// by other elements or positioned outside of the visible area of a viewport.
  ///
  /// Hidden elements cannot gain accessibility focus though regular touch. The
  /// only way they can be focused is by moving the focus to them via linear
  /// navigation.
  ///
  /// Platforms are free to completely ignore hidden elements and new platforms
  /// are encouraged to do so.
  ///
  /// Instead of marking an element as hidden it should usually be excluded from
  /// the semantics tree altogether. Hidden elements are only included in the
  /// semantics tree to work around platform limitations and they are mainly
  /// used to implement accessibility scrolling on iOS.
  bool get isHidden => _hasFlag(SemanticsFlag.isHidden);
  set isHidden(bool value) {
    _setFlag(SemanticsFlag.isHidden, value);
  }

  /// Whether the owning [RenderObject] is a text field.
  bool get isTextField => _hasFlag(SemanticsFlag.isTextField);
  set isTextField(bool value) {
    _setFlag(SemanticsFlag.isTextField, value);
  }

  /// Whether the [value] should be obscured.
  ///
  /// This option is usually set in combination with [textField] to indicate
  /// that the text field contains a password (or other sensitive information).
  /// Doing so instructs screen readers to not read out the [value].
  bool get isObscured => _hasFlag(SemanticsFlag.isObscured);
  set isObscured(bool value) {
    _setFlag(SemanticsFlag.isObscured, value);
  }

  /// Whether the platform can scroll the semantics node when the user attempts
  /// to move focus to an offscreen child.
  ///
  /// For example, a [ListView] widget has implicit scrolling so that users can
  /// easily move to the next visible set of children. A [TabBar] widget does
  /// not have implicit scrolling, so that users can navigate into the tab
  /// body when reaching the end of the tab bar.
  bool get hasImplicitScrolling => _hasFlag(SemanticsFlag.hasImplicitScrolling);
  set hasImplicitScrolling(bool value) {
    _setFlag(SemanticsFlag.hasImplicitScrolling, value);
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
    _tagsForChildren ??= Set<SemanticsTag>();
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
    _customSemanticsActions.addAll(other._customSemanticsActions);
    _actionsAsBits |= other._actionsAsBits;
    _flags |= other._flags;
    _textSelection ??= other._textSelection;
    _scrollPosition ??= other._scrollPosition;
    _scrollExtentMax ??= other._scrollExtentMax;
    _scrollExtentMin ??= other._scrollExtentMin;
    _hintOverrides ??= other._hintOverrides;
    _indexInParent ??= other.indexInParent;
    _scrollIndex ??= other._scrollIndex;
    _scrollChildCount ??= other._scrollChildCount;

    textDirection ??= other.textDirection;
    _sortKey ??= other._sortKey;
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
    return SemanticsConfiguration()
      .._isSemanticBoundary = _isSemanticBoundary
      ..explicitChildNodes = explicitChildNodes
      ..isBlockingSemanticsOfPreviouslyPaintedNodes = isBlockingSemanticsOfPreviouslyPaintedNodes
      .._hasBeenAnnotated = _hasBeenAnnotated
      .._isMergingSemanticsOfDescendants = _isMergingSemanticsOfDescendants
      .._textDirection = _textDirection
      .._sortKey = _sortKey
      .._label = _label
      .._increasedValue = _increasedValue
      .._value = _value
      .._decreasedValue = _decreasedValue
      .._hint = _hint
      .._hintOverrides = _hintOverrides
      .._flags = _flags
      .._tagsForChildren = _tagsForChildren
      .._textSelection = _textSelection
      .._scrollPosition = _scrollPosition
      .._scrollExtentMax = _scrollExtentMax
      .._scrollExtentMin = _scrollExtentMin
      .._actionsAsBits = _actionsAsBits
      .._indexInParent = indexInParent
      .._scrollIndex = _scrollIndex
      .._scrollChildCount = _scrollChildCount
      .._actions.addAll(_actions)
      .._customSemanticsActions.addAll(_customSemanticsActions);
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

  /// Print nodes in semantic traversal order.
  ///
  /// This is the order in which a user would navigate the UI using the "next"
  /// and "previous" gestures.
  traversalOrder,
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

/// Base class for all sort keys for [Semantics] accessibility traversal order
/// sorting.
///
/// Only keys of the same type and having matching [name]s are compared. If a
/// list of sibling [SemanticsNode]s contains keys that are not comparable with
/// each other the list is first sorted using the default sorting algorithm.
/// Then the nodes are broken down into groups by moving comparable nodes
/// towards the _earliest_ node in the group. Finally each group is sorted by
/// sort key and the resulting list is made by concatenating the sorted groups
/// back.
///
/// For example, let's take nodes (C, D, B, E, A, F). Let's assign node A key 1,
/// node B key 2, node C key 3. Let's also assume that the default sort order
/// leaves the original list intact. Because nodes A, B, and C, have comparable
/// sort key, they will form a group by pulling all nodes towards the earliest
/// node, which is C. The result is group (C, B, A). The remaining nodes D, E,
/// F, form a second group with sort key being `null`. The first group is sorted
/// using their sort keys becoming (A, B, C). The second group is left as is
/// because it does not specify sort keys. Then we concatenate the two groups -
/// (A, B, C) and (D, E, F) - into the final (A, B, C, D, E, F).
///
/// Because of the complexity introduced by incomparable sort keys among sibling
/// nodes, it is recommended to either use comparable keys for all nodes, or
/// use null for all of them, leaving the sort order to the default algorithm.
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
  /// they are of the same [runtimeType].
  final String name;

  @override
  int compareTo(SemanticsSortKey other) {
    // The sorting algorithm must not compare incomparable keys.
    assert(runtimeType == other.runtimeType);
    assert(name == other.name);
    return doCompare(other);
  }

  /// The implementation of [compareTo].
  ///
  /// The argument is guaranteed to be of the same type as this object and have
  /// the same [name].
  ///
  /// The method should return a negative number if this object comes earlier in
  /// the sort order than the argument; and a positive number if it comes later
  /// in the sort order. Returning zero causes the system to use default sort
  /// order.
  @protected
  int doCompare(covariant SemanticsSortKey other);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('name', name, defaultValue: null));
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('order', order, defaultValue: null));
  }
}
