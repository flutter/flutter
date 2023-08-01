// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../../engine.dart'  show registerHotRestartListener;
import '../alarm_clock.dart';
import '../browser_detection.dart';
import '../configuration.dart';
import '../dom.dart';
import '../embedder.dart';
import '../platform_dispatcher.dart';
import '../util.dart';
import '../vector_math.dart';
import 'checkable.dart';
import 'dialog.dart';
import 'focusable.dart';
import 'image.dart';
import 'incrementable.dart';
import 'label_and_value.dart';
import 'live_region.dart';
import 'platform_view.dart';
import 'scrollable.dart';
import 'semantics_helper.dart';
import 'tappable.dart';
import 'text_field.dart';

class EngineAccessibilityFeatures implements ui.AccessibilityFeatures {
  const EngineAccessibilityFeatures(this._index);

  static const int _kAccessibleNavigation = 1 << 0;
  static const int _kInvertColorsIndex = 1 << 1;
  static const int _kDisableAnimationsIndex = 1 << 2;
  static const int _kBoldTextIndex = 1 << 3;
  static const int _kReduceMotionIndex = 1 << 4;
  static const int _kHighContrastIndex = 1 << 5;
  static const int _kOnOffSwitchLabelsIndex = 1 << 6;

  // A bitfield which represents each enabled feature.
  final int _index;

  @override
  bool get accessibleNavigation => _kAccessibleNavigation & _index != 0;
  @override
  bool get invertColors => _kInvertColorsIndex & _index != 0;
  @override
  bool get disableAnimations => _kDisableAnimationsIndex & _index != 0;
  @override
  bool get boldText => _kBoldTextIndex & _index != 0;
  @override
  bool get reduceMotion => _kReduceMotionIndex & _index != 0;
  @override
  bool get highContrast => _kHighContrastIndex & _index != 0;
  @override
  bool get onOffSwitchLabels => _kOnOffSwitchLabelsIndex & _index != 0;

  @override
  String toString() {
    final List<String> features = <String>[];
    if (accessibleNavigation) {
      features.add('accessibleNavigation');
    }
    if (invertColors) {
      features.add('invertColors');
    }
    if (disableAnimations) {
      features.add('disableAnimations');
    }
    if (boldText) {
      features.add('boldText');
    }
    if (reduceMotion) {
      features.add('reduceMotion');
    }
    if (highContrast) {
      features.add('highContrast');
    }
    if (onOffSwitchLabels) {
      features.add('onOffSwitchLabels');
    }
    return 'AccessibilityFeatures$features';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is EngineAccessibilityFeatures && other._index == _index;
  }

  @override
  int get hashCode => _index.hashCode;

  EngineAccessibilityFeatures copyWith({
      bool? accessibleNavigation,
      bool? invertColors,
      bool? disableAnimations,
      bool? boldText,
      bool? reduceMotion,
      bool? highContrast,
      bool? onOffSwitchLabels})
  {
    final EngineAccessibilityFeaturesBuilder builder = EngineAccessibilityFeaturesBuilder(0);

    builder.accessibleNavigation = accessibleNavigation ?? this.accessibleNavigation;
    builder.invertColors = invertColors ?? this.invertColors;
    builder.disableAnimations = disableAnimations ?? this.disableAnimations;
    builder.boldText = boldText ?? this.boldText;
    builder.reduceMotion = reduceMotion ?? this.reduceMotion;
    builder.highContrast = highContrast ?? this.highContrast;
    builder.onOffSwitchLabels = onOffSwitchLabels ?? this.onOffSwitchLabels;

    return builder.build();
  }
}

class EngineAccessibilityFeaturesBuilder {
  EngineAccessibilityFeaturesBuilder(this._index);

  int _index = 0;

  bool get accessibleNavigation => EngineAccessibilityFeatures._kAccessibleNavigation & _index != 0;
  bool get invertColors => EngineAccessibilityFeatures._kInvertColorsIndex & _index != 0;
  bool get disableAnimations => EngineAccessibilityFeatures._kDisableAnimationsIndex & _index != 0;
  bool get boldText => EngineAccessibilityFeatures._kBoldTextIndex & _index != 0;
  bool get reduceMotion => EngineAccessibilityFeatures._kReduceMotionIndex & _index != 0;
  bool get highContrast => EngineAccessibilityFeatures._kHighContrastIndex & _index != 0;
  bool get onOffSwitchLabels => EngineAccessibilityFeatures._kOnOffSwitchLabelsIndex & _index != 0;

  set accessibleNavigation(bool value) {
    const int accessibleNavigation = EngineAccessibilityFeatures._kAccessibleNavigation;
    _index = value? _index | accessibleNavigation : _index & ~accessibleNavigation;
  }

  set invertColors(bool value) {
    const int invertColors = EngineAccessibilityFeatures._kInvertColorsIndex;
    _index = value? _index | invertColors : _index & ~invertColors;
  }

  set disableAnimations(bool value) {
    const int disableAnimations = EngineAccessibilityFeatures._kDisableAnimationsIndex;
    _index = value? _index | disableAnimations : _index & ~disableAnimations;
  }

  set boldText(bool value) {
    const int boldText = EngineAccessibilityFeatures._kBoldTextIndex;
    _index = value? _index | boldText : _index & ~boldText;
  }

  set reduceMotion(bool value) {
    const int reduceMotion = EngineAccessibilityFeatures._kReduceMotionIndex;
    _index = value? _index | reduceMotion : _index & ~reduceMotion;
  }

  set highContrast(bool value) {
    const int highContrast = EngineAccessibilityFeatures._kHighContrastIndex;
    _index = value? _index | highContrast : _index & ~highContrast;
  }

  set onOffSwitchLabels(bool value) {
    const int onOffSwitchLabels = EngineAccessibilityFeatures._kOnOffSwitchLabelsIndex;
    _index = value? _index | onOffSwitchLabels : _index & ~onOffSwitchLabels;
  }

  /// Creates and returns an instance of EngineAccessibilityFeatures based on the value of _index
  EngineAccessibilityFeatures build() {
    return EngineAccessibilityFeatures(_index);
  }
}

/// Contains updates for the semantics tree.
///
/// This class provides private engine-side API that's not available in the
/// `dart:ui` [ui.SemanticsUpdate].
class SemanticsUpdate implements ui.SemanticsUpdate {
  SemanticsUpdate({List<SemanticsNodeUpdate>? nodeUpdates})
      : _nodeUpdates = nodeUpdates;

  /// Updates for individual nodes.
  final List<SemanticsNodeUpdate>? _nodeUpdates;

  @override
  void dispose() {
    // Intentionally left blank. This method exists for API compatibility with
    // Flutter, but it is not required as memory resource management is handled
    // by JavaScript's garbage collector.
  }
}

/// Updates the properties of a particular semantics node.
class SemanticsNodeUpdate {
  SemanticsNodeUpdate({
    required this.id,
    required this.flags,
    required this.actions,
    required this.maxValueLength,
    required this.currentValueLength,
    required this.textSelectionBase,
    required this.textSelectionExtent,
    required this.platformViewId,
    required this.scrollChildren,
    required this.scrollIndex,
    required this.scrollPosition,
    required this.scrollExtentMax,
    required this.scrollExtentMin,
    required this.rect,
    required this.label,
    required this.labelAttributes,
    required this.hint,
    required this.hintAttributes,
    required this.value,
    required this.valueAttributes,
    required this.increasedValue,
    required this.increasedValueAttributes,
    required this.decreasedValue,
    required this.decreasedValueAttributes,
    this.tooltip,
    this.textDirection,
    required this.transform,
    required this.elevation,
    required this.thickness,
    required this.childrenInTraversalOrder,
    required this.childrenInHitTestOrder,
    required this.additionalActions,
  });

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int id;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int flags;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int actions;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int maxValueLength;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int currentValueLength;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int textSelectionBase;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int textSelectionExtent;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int platformViewId;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int scrollChildren;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final int scrollIndex;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final double scrollPosition;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final double scrollExtentMax;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final double scrollExtentMin;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final ui.Rect rect;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final String label;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final List<ui.StringAttribute> labelAttributes;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final String hint;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final List<ui.StringAttribute> hintAttributes;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final String value;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final List<ui.StringAttribute> valueAttributes;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final String increasedValue;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final List<ui.StringAttribute> increasedValueAttributes;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final String decreasedValue;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final List<ui.StringAttribute> decreasedValueAttributes;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final String? tooltip;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final ui.TextDirection? textDirection;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final Float32List transform;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final Int32List childrenInTraversalOrder;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final Int32List childrenInHitTestOrder;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final Int32List additionalActions;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final double elevation;

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  final double thickness;
}

/// Identifies [PrimaryRoleManager] implementations.
///
/// Each value corresponds to the most specific role a semantics node plays in
/// the semantics tree.
enum PrimaryRole {
  /// Supports incrementing and/or decrementing its value.
  incrementable,

  /// Able to scroll its contents vertically or horizontally.
  scrollable,

  /// Accepts tap or click gestures.
  button,

  /// Contains editable text.
  textField,

  /// A control that has a checked state, such as a check box or a radio button.
  checkable,

  /// Visual only element.
  image,

  /// Adds the "dialog" ARIA role to the node.
  ///
  /// This corresponds to a semantics node that has `scopesRoute` bit set. While
  /// in Flutter a named route is not necessarily a dialog, this is the closest
  /// analog on the web.
  ///
  /// There are 3 possible situations:
  ///
  /// * The node also has the `namesRoute` bit set. This means that the node's
  ///   `label` describes the dialog, which can be expressed by adding the
  ///   `aria-label` attribute.
  /// * A descendant node has the `namesRoute` bit set. This means that the
  ///   child's content describes the dialog. The child may simply be labelled,
  ///   or it may be a subtree of nodes that describe the dialog together. The
  ///   nearest HTML equivalent is `aria-describedby`. The child acquires the
  ///   [routeName] role, which manages the relevant ARIA attributes.
  /// * There is no `namesRoute` bit anywhere in the sub-tree rooted at the
  ///   current node. In this case it's likely not a dialog at all, and the node
  ///   should not get a label or the "dialog" role. It's just a group of
  ///   children. For example, a modal barrier has `scopesRoute` set but marking
  ///   it as a dialog would be wrong.
  dialog,

  /// The node's primary role is to host a platform view.
  platformView,

  /// A role used when a more specific role cannot be assigend to
  /// a [SemanticsObject].
  ///
  /// Provides a label or a value.
  generic,
}

/// Identifies one of the secondary [RoleManager]s of a [PrimaryRoleManager].
enum Role {
  /// Supplies generic accessibility focus features to semantics nodes that have
  /// [ui.SemanticsFlag.isFocusable] set.
  focusable,

  /// Supplies generic tapping/clicking functionality.
  tappable,

  /// Provides an `aria-label` from `label`, `value`, and/or `tooltip` values.
  ///
  /// The two are combined into the same role because they interact with each
  /// other.
  labelAndValue,

  /// Contains a region whose changes will be announced to the screen reader
  /// without having to be in focus.
  ///
  /// These regions can be a snackbar or a text field error. Once identified
  /// with this role, they will be able to get the assistive technology's
  /// attention right away.
  liveRegion,

  /// Provides a description for an ancestor dialog.
  ///
  /// This role is assigned to nodes that have `namesRoute` set but not
  /// `scopesRoute`. When both flags are set the node only gets the dialog
  /// role (see [dialog]).
  ///
  /// If the ancestor dialog is missing, this role does nothing useful.
  routeName,
}

/// Responsible for setting the `role` ARIA attribute and for attaching zero or
/// more secondary [RoleManager]s to a [SemanticsObject].
abstract class PrimaryRoleManager {
  /// Initializes a role for a [semanticsObject] that includes basic
  /// functionality for focus, labels, live regions, and route names.
  PrimaryRoleManager.withBasics(this.role, this.semanticsObject) {
    addFocusManagement();
    addLiveRegion();
    addRouteName();
    addLabelAndValue();
    addTappable();
  }

  /// Initializes a blank role for a [semanticsObject].
  ///
  /// Use this constructor for highly specialized cases where
  /// [RoleManager.withBasics] does not work, for example when the default focus
  /// management intereferes with the widget's functionality.
  PrimaryRoleManager.blank(this.role, this.semanticsObject);

  /// The primary role identifier.
  final PrimaryRole role;

  /// The semantics object managed by this role.
  final SemanticsObject semanticsObject;

  /// Secondary role managers, if any.
  List<RoleManager>? get secondaryRoleManagers => _secondaryRoleManagers;
  List<RoleManager>? _secondaryRoleManagers;

  /// Identifiers of secondary roles used by this primary role manager.
  ///
  /// This is only meant to be used in tests.
  @visibleForTesting
  List<Role> get debugSecondaryRoles => _secondaryRoleManagers?.map((RoleManager manager) => manager.role).toList() ?? const <Role>[];

  /// Adds generic focus management features.
  void addFocusManagement() {
    addSecondaryRole(Focusable(semanticsObject));
  }

  /// Adds generic live region features.
  void addLiveRegion() {
    addSecondaryRole(LiveRegion(semanticsObject));
  }

  /// Adds generic route name features.
  void addRouteName() {
    addSecondaryRole(RouteName(semanticsObject));
  }

  /// Adds generic label features.
  void addLabelAndValue() {
    addSecondaryRole(LabelAndValue(semanticsObject));
  }

  /// Adds generic functionality for handling taps and clicks.
  void addTappable() {
    addSecondaryRole(Tappable(semanticsObject));
  }

  /// Adds a secondary role to this primary role manager.
  ///
  /// This method should be called by concrete implementations of
  /// [PrimaryRoleManager] during initialization.
  @protected
  void addSecondaryRole(RoleManager secondaryRoleManager) {
    assert(
      _secondaryRoleManagers?.any((RoleManager manager) => manager.role == secondaryRoleManager.role) != true,
      'Cannot add secondary role ${secondaryRoleManager.role}. This object already has this secondary role.',
    );
    _secondaryRoleManagers ??= <RoleManager>[];
    _secondaryRoleManagers!.add(secondaryRoleManager);
  }

  /// Called immediately after the fields of the [semanticsObject] are updated
  /// by a [SemanticsUpdate].
  ///
  /// A concrete implementation of this method would typically use some of the
  /// "is*Dirty" getters to find out exactly what's changed and apply the
  /// minimum DOM updates.
  ///
  /// The base implementation requests every secondary role manager to update
  /// the object.
  @mustCallSuper
  void update() {
    final List<RoleManager>? secondaryRoles = _secondaryRoleManagers;
    if (secondaryRoles == null) {
      return;
    }
    for (final RoleManager secondaryRole in secondaryRoles) {
      secondaryRole.update();
    }
  }

  /// Whether this role manager was disposed of.
  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  /// Called when [semanticsObject] is removed, or when it changes its role such
  /// that this role is no longer relevant.
  ///
  /// This method is expected to remove role-specific functionality from the
  /// DOM. In particular, this method is the appropriate place to call
  /// [EngineSemanticsOwner.removeGestureModeListener] if this role reponds to
  /// gesture mode changes.
  @mustCallSuper
  void dispose() {
    semanticsObject.element.removeAttribute('role');
    _isDisposed = true;
  }
}

/// A role used when a more specific role couldn't be assigned to the node.
final class GenericRole extends PrimaryRoleManager {
  GenericRole(SemanticsObject semanticsObject) : super.withBasics(PrimaryRole.generic, semanticsObject);

  @override
  void update() {
    super.update();

    if (!semanticsObject.hasLabel) {
      // The node didn't get a more specific role, and it has no label. It is
      // likely that this node is simply there for positioning its children and
      // has no other role for the screen reader to be aware of. In this case,
      // the element does not need a `role` attribute at all.
      return;
    }

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
      semanticsObject.setAriaRole('group');
    } else if (semanticsObject.hasFlag(ui.SemanticsFlag.isHeader)) {
      semanticsObject.setAriaRole('heading');
    } else {
      semanticsObject.setAriaRole('text');
    }
  }
}

/// Provides a piece of functionality to a [SemanticsObject].
///
/// A secondary role must not set the `role` ARIA attribute. That responsibility
/// falls on the [PrimaryRoleManager]. One [SemanticsObject] may have more than
/// one [RoleManager] but an element may only have one ARIA role, so setting the
/// `role` attribute from a [RoleManager] would cause conflicts.
///
/// The [PrimaryRoleManager] decides the list of [RoleManager]s a given semantics
/// node should use.
abstract class RoleManager {
  /// Initializes a secondary role for [semanticsObject].
  ///
  /// A single role object manages exactly one [SemanticsObject].
  RoleManager(this.role, this.semanticsObject);

  /// Role identifier.
  final Role role;

  /// The semantics object managed by this role.
  final SemanticsObject semanticsObject;

  /// Called immediately after the [semanticsObject] updates some of its fields.
  ///
  /// A concrete implementation of this method would typically use some of the
  /// "is*Dirty" getters to find out exactly what's changed and apply the
  /// minimum DOM updates.
  void update();

  /// Whether this role manager was disposed of.
  bool get isDisposed => _isDisposed;
  bool _isDisposed = false;

  /// Called when [semanticsObject] is removed, or when it changes its role such
  /// that this role is no longer relevant.
  ///
  /// This method is expected to remove role-specific functionality from the
  /// DOM. In particular, this method is the appropriate place to call
  /// [EngineSemanticsOwner.removeGestureModeListener] if this role reponds to
  /// gesture mode changes.
  @mustCallSuper
  void dispose() {
    _isDisposed = true;
  }
}

/// Instantiation of a framework-side semantics node in the DOM.
///
/// Instances of this class are retained from frame to frame. Each instance is
/// permanently attached to an [id] and a DOM [element] used to convey semantics
/// information to the browser.
class SemanticsObject {
  /// Creates a semantics tree node with the given [id] and [owner].
  SemanticsObject(this.id, this.owner) {
    // DOM nodes created for semantics objects are positioned absolutely using
    // transforms.
    element.style.position = 'absolute';
    element.setAttribute('id', 'flt-semantic-node-$id');

    // The root node has some properties that other nodes do not.
    if (id == 0 && !configuration.debugShowSemanticsNodes) {
      // Make all semantics transparent. Use `filter` instead of `opacity`
      // attribute because `filter` is stronger. `opacity` does not apply to
      // some elements, particularly on iOS, such as the slider thumb and track.
      //
      // Use transparency instead of "visibility:hidden" or "display:none"
      // so that a screen reader does not ignore these elements.
      element.style.filter = 'opacity(0%)';

      // Make text explicitly transparent to signal to the browser that no
      // rasterization needs to be done.
      element.style.color = 'rgba(0,0,0,0)';
    }

    // Make semantic elements visible for debugging by outlining them using a
    // green border. Do not use `border` attribute because it affects layout
    // (`outline` does not).
    if (configuration.debugShowSemanticsNodes) {
      element.style.outline = '1px solid green';
    }
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  int get flags => _flags;
  int _flags = 0;

  /// Whether the [flags] field has been updated but has not been applied to the
  /// DOM yet.
  bool get isFlagsDirty => _isDirty(_flagsIndex);
  static const int _flagsIndex = 1 << 0;
  void _markFlagsDirty() {
    _dirtyFields |= _flagsIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  int? get actions => _actions;
  int? _actions;

  static const int _actionsIndex = 1 << 1;

  /// Whether the [actions] field has been updated but has not been applied to
  /// the DOM yet.
  bool get isActionsDirty => _isDirty(_actionsIndex);
  void _markActionsDirty() {
    _dirtyFields |= _actionsIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  int? get textSelectionBase => _textSelectionBase;
  int? _textSelectionBase;

  static const int _textSelectionBaseIndex = 1 << 2;

  /// Whether the [textSelectionBase] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isTextSelectionBaseDirty => _isDirty(_textSelectionBaseIndex);
  void _markTextSelectionBaseDirty() {
    _dirtyFields |= _textSelectionBaseIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  int? get textSelectionExtent => _textSelectionExtent;
  int? _textSelectionExtent;

  static const int _textSelectionExtentIndex = 1 << 3;

  /// Whether the [textSelectionExtent] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isTextSelectionExtentDirty => _isDirty(_textSelectionExtentIndex);
  void _markTextSelectionExtentDirty() {
    _dirtyFields |= _textSelectionExtentIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  int? get scrollChildren => _scrollChildren;
  int? _scrollChildren;

  static const int _scrollChildrenIndex = 1 << 4;

  /// Whether the [scrollChildren] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isScrollChildrenDirty => _isDirty(_scrollChildrenIndex);
  void _markScrollChildrenDirty() {
    _dirtyFields |= _scrollChildrenIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  int? get scrollIndex => _scrollIndex;
  int? _scrollIndex;

  static const int _scrollIndexIndex = 1 << 5;

  /// Whether the [scrollIndex] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isScrollIndexDirty => _isDirty(_scrollIndexIndex);
  void _markScrollIndexDirty() {
    _dirtyFields |= _scrollIndexIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  double? get scrollPosition => _scrollPosition;
  double? _scrollPosition;

  static const int _scrollPositionIndex = 1 << 6;

  /// Whether the [scrollPosition] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isScrollPositionDirty => _isDirty(_scrollPositionIndex);
  void _markScrollPositionDirty() {
    _dirtyFields |= _scrollPositionIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  double? get scrollExtentMax => _scrollExtentMax;
  double? _scrollExtentMax;

  static const int _scrollExtentMaxIndex = 1 << 7;

  /// Whether the [scrollExtentMax] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isScrollExtentMaxDirty => _isDirty(_scrollExtentMaxIndex);
  void _markScrollExtentMaxDirty() {
    _dirtyFields |= _scrollExtentMaxIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  double? get scrollExtentMin => _scrollExtentMin;
  double? _scrollExtentMin;

  static const int _scrollExtentMinIndex = 1 << 8;

  /// Whether the [scrollExtentMin] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isScrollExtentMinDirty => _isDirty(_scrollExtentMinIndex);
  void _markScrollExtentMinDirty() {
    _dirtyFields |= _scrollExtentMinIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  ui.Rect? get rect => _rect;
  ui.Rect? _rect;

  static const int _rectIndex = 1 << 9;

  /// Whether the [rect] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isRectDirty => _isDirty(_rectIndex);
  void _markRectDirty() {
    _dirtyFields |= _rectIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  String? get label => _label;
  String? _label;

  /// See [ui.SemanticsUpdateBuilder.updateNode]
  List<ui.StringAttribute>? get labelAttributes => _labelAttributes;
  List<ui.StringAttribute>? _labelAttributes;

  /// Whether this object contains a non-empty label.
  bool get hasLabel => _label != null && _label!.isNotEmpty;

  static const int _labelIndex = 1 << 10;

  /// Whether the [label] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isLabelDirty => _isDirty(_labelIndex);
  void _markLabelDirty() {
    _dirtyFields |= _labelIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  String? get hint => _hint;
  String? _hint;

  /// See [ui.SemanticsUpdateBuilder.updateNode]
  List<ui.StringAttribute>? get hintAttributes => _hintAttributes;
  List<ui.StringAttribute>? _hintAttributes;

  static const int _hintIndex = 1 << 11;

  /// Whether the [hint] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isHintDirty => _isDirty(_hintIndex);
  void _markHintDirty() {
    _dirtyFields |= _hintIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  String? get value => _value;
  String? _value;

  /// See [ui.SemanticsUpdateBuilder.updateNode]
  List<ui.StringAttribute>? get valueAttributes => _valueAttributes;
  List<ui.StringAttribute>? _valueAttributes;

  /// Whether this object contains a non-empty value.
  bool get hasValue => _value != null && _value!.isNotEmpty;

  static const int _valueIndex = 1 << 12;

  /// Whether the [value] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isValueDirty => _isDirty(_valueIndex);
  void _markValueDirty() {
    _dirtyFields |= _valueIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  String? get increasedValue => _increasedValue;
  String? _increasedValue;

  /// See [ui.SemanticsUpdateBuilder.updateNode]
  List<ui.StringAttribute>? get increasedValueAttributes => _increasedValueAttributes;
  List<ui.StringAttribute>? _increasedValueAttributes;

  static const int _increasedValueIndex = 1 << 13;

  /// Whether the [increasedValue] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isIncreasedValueDirty => _isDirty(_increasedValueIndex);
  void _markIncreasedValueDirty() {
    _dirtyFields |= _increasedValueIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  String? get decreasedValue => _decreasedValue;
  String? _decreasedValue;

  /// See [ui.SemanticsUpdateBuilder.updateNode]
  List<ui.StringAttribute>? get decreasedValueAttributes => _decreasedValueAttributes;
  List<ui.StringAttribute>? _decreasedValueAttributes;

  static const int _decreasedValueIndex = 1 << 14;

  /// Whether the [decreasedValue] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isDecreasedValueDirty => _isDirty(_decreasedValueIndex);
  void _markDecreasedValueDirty() {
    _dirtyFields |= _decreasedValueIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  ui.TextDirection? get textDirection => _textDirection;
  ui.TextDirection? _textDirection;

  static const int _textDirectionIndex = 1 << 15;

  /// Whether the [textDirection] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isTextDirectionDirty => _isDirty(_textDirectionIndex);
  void _markTextDirectionDirty() {
    _dirtyFields |= _textDirectionIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  Float32List? get transform => _transform;
  Float32List? _transform;

  static const int _transformIndex = 1 << 16;

  /// Whether the [transform] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isTransformDirty => _isDirty(_transformIndex);
  void _markTransformDirty() {
    _dirtyFields |= _transformIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  Int32List? get childrenInTraversalOrder => _childrenInTraversalOrder;
  Int32List? _childrenInTraversalOrder;

  static const int _childrenInTraversalOrderIndex = 1 << 19;

  /// Whether the [childrenInTraversalOrder] field has been updated but has not
  /// been applied to the DOM yet.
  bool get isChildrenInTraversalOrderDirty =>
      _isDirty(_childrenInTraversalOrderIndex);
  void _markChildrenInTraversalOrderDirty() {
    _dirtyFields |= _childrenInTraversalOrderIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  Int32List? get childrenInHitTestOrder => _childrenInHitTestOrder;
  Int32List? _childrenInHitTestOrder;

  static const int _childrenInHitTestOrderIndex = 1 << 20;

  /// Whether the [childrenInHitTestOrder] field has been updated but has not
  /// been applied to the DOM yet.
  bool get isChildrenInHitTestOrderDirty =>
      _isDirty(_childrenInHitTestOrderIndex);
  void _markChildrenInHitTestOrderDirty() {
    _dirtyFields |= _childrenInHitTestOrderIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  Int32List? get additionalActions => _additionalActions;
  Int32List? _additionalActions;

  static const int _additionalActionsIndex = 1 << 21;

  /// Whether the [additionalActions] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isAdditionalActionsDirty => _isDirty(_additionalActionsIndex);
  void _markAdditionalActionsDirty() {
    _dirtyFields |= _additionalActionsIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  String? get tooltip => _tooltip;
  String? _tooltip;

  /// Whether this object contains a non-empty tooltip.
  bool get hasTooltip => _tooltip != null && _tooltip!.isNotEmpty;

  static const int _tooltipIndex = 1 << 22;

  /// Whether the [tooltip] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isTooltipDirty => _isDirty(_tooltipIndex);
  void _markTooltipDirty() {
    _dirtyFields |= _tooltipIndex;
  }

  /// See [ui.SemanticsUpdateBuilder.updateNode].
  int get platformViewId => _platformViewId;
  int _platformViewId = -1;

  /// Whether this object represents a platform view.
  bool get isPlatformView => _platformViewId != -1;

  static const int _platformViewIdIndex = 1 << 23;

  /// Whether the [platformViewId] field has been updated but has not been
  /// applied to the DOM yet.
  bool get isPlatformViewIdDirty => _isDirty(_platformViewIdIndex);
  void _markPlatformViewIdDirty() {
    _dirtyFields |= _platformViewIdIndex;
  }

  /// A unique permanent identifier of the semantics node in the tree.
  final int id;

  /// Controls the semantics tree that this node participates in.
  final EngineSemanticsOwner owner;

  /// The DOM element used to convey semantics information to the browser.
  final DomElement element = domDocument.createElement('flt-semantics');

  /// Bitfield showing which fields have been updated but have not yet been
  /// applied to the DOM.
  ///
  /// Instead of use this field directly, prefer using one of the "is*Dirty"
  /// getters, e.g. [isFlagsDirty].
  ///
  /// The bitfield supports up to 31 bits.
  int _dirtyFields = -1; // initial value is when all relevant bits are set

  /// Whether the field corresponding to the [fieldIndex] has been updated.
  bool _isDirty(int fieldIndex) => (_dirtyFields & fieldIndex) != 0;

  /// Returns the HTML element that contains the HTML elements of direct
  /// children of this object.
  ///
  /// The element is created lazily. When the child list is empty this element
  /// is not created. This is necessary for "aria-label" to function correctly.
  /// The browser will ignore the [label] of HTML element that contain child
  /// elements.
  DomElement? getOrCreateChildContainer() {
    if (_childContainerElement == null) {
      _childContainerElement = createDomElement('flt-semantics-container');
      _childContainerElement!.style
        ..position = 'absolute'
        // Ignore pointer events on child container so that platform views
        // behind it can be reached.
        ..pointerEvents = 'none';
      element.append(_childContainerElement!);
    }
    return _childContainerElement;
  }

  /// The element that contains the elements belonging to the child semantics
  /// nodes.
  ///
  /// This element is used to correct for [_rect] offsets. It is only non-`null`
  /// when there are non-zero children (i.e. when [hasChildren] is `true`).
  DomElement? _childContainerElement;

  /// The parent of this semantics object.
  ///
  /// This value is not final until the tree is finalized. It is not safe to
  /// rely on this value in the middle of a semantics tree update. It is safe to
  /// use this value in post-update callback (see [SemanticsUpdatePhase] and
  /// [EngineSemanticsOwner.addOneTimePostUpdateCallback]).
  SemanticsObject? get parent {
    assert(owner.phase == SemanticsUpdatePhase.postUpdate);
    return _parent;
  }
  SemanticsObject? _parent;

  /// Whether this node currently has a given [SemanticsFlag].
  bool hasFlag(ui.SemanticsFlag flag) => _flags & flag.index != 0;

  /// Whether [actions] contains the given action.
  bool hasAction(ui.SemanticsAction action) => (_actions! & action.index) != 0;

  /// Whether this object represents a widget that can receive input focus.
  bool get isFocusable => hasFlag(ui.SemanticsFlag.isFocusable);

  /// Whether this object currently has input focus.
  ///
  /// This value only makes sense if [isFocusable] is true.
  bool get hasFocus => hasFlag(ui.SemanticsFlag.isFocused);

  /// Whether this object can be in one of "enabled" or "disabled" state.
  ///
  /// If this is true, [isEnabled] communicates the state.
  bool get hasEnabledState => hasFlag(ui.SemanticsFlag.hasEnabledState);

  /// Whether this object is enabled.
  ///
  /// This field is only meaningful if [hasEnabledState] is true.
  bool get isEnabled => hasFlag(ui.SemanticsFlag.isEnabled);

  /// Whether this object represents a vertically scrollable area.
  bool get isVerticalScrollContainer =>
      hasAction(ui.SemanticsAction.scrollDown) ||
      hasAction(ui.SemanticsAction.scrollUp);

  /// Whether this object represents a horizontally scrollable area.
  bool get isHorizontalScrollContainer =>
      hasAction(ui.SemanticsAction.scrollLeft) ||
      hasAction(ui.SemanticsAction.scrollRight);

  /// Whether this object represents a scrollable area in any direction.
  bool get isScrollContainer => isVerticalScrollContainer || isHorizontalScrollContainer;

  /// Whether this object has a non-empty list of children.
  bool get hasChildren =>
      _childrenInTraversalOrder != null && _childrenInTraversalOrder!.isNotEmpty;

  /// Whether this object represents an editable text field.
  bool get isTextField => hasFlag(ui.SemanticsFlag.isTextField);

  /// Whether this object needs screen readers attention right away.
  bool get isLiveRegion =>
      hasFlag(ui.SemanticsFlag.isLiveRegion) &&
      !hasFlag(ui.SemanticsFlag.isHidden);

  /// Whether this object represents an image with no tappable functionality.
  bool get isVisualOnly =>
      hasFlag(ui.SemanticsFlag.isImage) &&
      !isTappable &&
      !isButton;

  /// Whether this node defines a scope for a route.
  ///
  /// See also [Role.dialog].
  bool get scopesRoute => hasFlag(ui.SemanticsFlag.scopesRoute);

  /// Whether this node describes a route.
  ///
  /// See also [Role.dialog].
  bool get namesRoute => hasFlag(ui.SemanticsFlag.namesRoute);

  /// Whether this object carry enabled/disabled state (and if so whether it is
  /// enabled).
  ///
  /// See [EnabledState] for more details.
  EnabledState enabledState() {
    if (hasFlag(ui.SemanticsFlag.hasEnabledState)) {
      if (hasFlag(ui.SemanticsFlag.isEnabled)) {
        return EnabledState.enabled;
      } else {
        return EnabledState.disabled;
      }
    } else {
      return EnabledState.noOpinion;
    }
  }

  /// Updates this object from data received from a semantics [update].
  ///
  /// Does not update children. Children are updated in a separate pass because
  /// at this point children's self information is not ready yet.
  void updateSelf(SemanticsNodeUpdate update) {
    // Update all field values and their corresponding dirty flags before
    // applying the updates to the DOM.
    if (_flags != update.flags) {
      _flags = update.flags;
      _markFlagsDirty();
    }

    if (_value != update.value) {
      _value = update.value;
      _markValueDirty();
    }

    if (_valueAttributes != update.valueAttributes) {
      _valueAttributes = update.valueAttributes;
      _markValueDirty();
    }

    if (_label != update.label) {
      _label = update.label;
      _markLabelDirty();
    }

    if (_labelAttributes != update.labelAttributes) {
      _labelAttributes = update.labelAttributes;
      _markLabelDirty();
    }

    if (_rect != update.rect) {
      _rect = update.rect;
      _markRectDirty();
    }

    if (_transform != update.transform) {
      _transform = update.transform;
      _markTransformDirty();
    }

    if (_scrollPosition != update.scrollPosition) {
      _scrollPosition = update.scrollPosition;
      _markScrollPositionDirty();
    }

    if (_actions != update.actions) {
      _actions = update.actions;
      _markActionsDirty();
    }

    if (_textSelectionBase != update.textSelectionBase) {
      _textSelectionBase = update.textSelectionBase;
      _markTextSelectionBaseDirty();
    }

    if (_textSelectionExtent != update.textSelectionExtent) {
      _textSelectionExtent = update.textSelectionExtent;
      _markTextSelectionExtentDirty();
    }

    if (_scrollChildren != update.scrollChildren) {
      _scrollChildren = update.scrollChildren;
      _markScrollChildrenDirty();
    }

    if (_scrollIndex != update.scrollIndex) {
      _scrollIndex = update.scrollIndex;
      _markScrollIndexDirty();
    }

    if (_scrollExtentMax != update.scrollExtentMax) {
      _scrollExtentMax = update.scrollExtentMax;
      _markScrollExtentMaxDirty();
    }

    if (_scrollExtentMin != update.scrollExtentMin) {
      _scrollExtentMin = update.scrollExtentMin;
      _markScrollExtentMinDirty();
    }

    if (_hint != update.hint) {
      _hint = update.hint;
      _markHintDirty();
    }

    if (_hintAttributes != update.hintAttributes) {
      _hintAttributes = update.hintAttributes;
      _markHintDirty();
    }

    if (_increasedValue != update.increasedValue) {
      _increasedValue = update.increasedValue;
      _markIncreasedValueDirty();
    }

    if (_increasedValueAttributes != update.increasedValueAttributes) {
      _increasedValueAttributes = update.increasedValueAttributes;
      _markIncreasedValueDirty();
    }

    if (_decreasedValue != update.decreasedValue) {
      _decreasedValue = update.decreasedValue;
      _markDecreasedValueDirty();
    }

    if (_decreasedValueAttributes != update.decreasedValueAttributes) {
      _decreasedValueAttributes = update.decreasedValueAttributes;
      _markDecreasedValueDirty();
    }

    if (_tooltip != update.tooltip) {
      _tooltip = update.tooltip;
      _markTooltipDirty();
    }

    if (_textDirection != update.textDirection) {
      _textDirection = update.textDirection;
      _markTextDirectionDirty();
    }

    if (_childrenInHitTestOrder != update.childrenInHitTestOrder) {
      _childrenInHitTestOrder = update.childrenInHitTestOrder;
      _markChildrenInHitTestOrderDirty();
    }

    if (_childrenInTraversalOrder != update.childrenInTraversalOrder) {
      _childrenInTraversalOrder = update.childrenInTraversalOrder;
      _markChildrenInTraversalOrderDirty();
    }

    if (_additionalActions != update.additionalActions) {
      _additionalActions = update.additionalActions;
      _markAdditionalActionsDirty();
    }

    if (_platformViewId != update.platformViewId) {
      _platformViewId = update.platformViewId;
      _markPlatformViewIdDirty();
    }

    // Apply updates to the DOM.
    _updateRoles();

    // All properties that affect positioning and sizing are checked together
    // any one of them triggers position and size recomputation.
    if (isRectDirty || isTransformDirty || isScrollPositionDirty) {
      recomputePositionAndSize();
    }

    // Ignore pointer events on all container nodes and all platform view nodes.
    // This is so that the platform views are not obscured by semantic elements
    // and can be reached by inspecting the web page.
    if (!hasChildren && !isPlatformView) {
      element.style.pointerEvents = 'all';
    } else {
      element.style.pointerEvents = 'none';
    }
  }

  /// The order children are currently rendered in.
  List<SemanticsObject>? _currentChildrenInRenderOrder;

  /// Updates direct children of this node, if any.
  ///
  /// Specifies two orders of direct children:
  ///
  /// * Traversal order: the logical order of child nodes that establishes the
  ///   next and previous relationship between UI widgets. When the user
  ///   traverses the UI using next/previous gestures the accessibility focus
  ///   follows the traversal order.
  /// * Hit-test order: determines the top/bottom relationship between widgets.
  ///   When the user is inspecting the UI using the drag gesture, the widgets
  ///   that appear "on top" hit-test order wise take the focus. This order is
  ///   communicated in the DOM using the inverse paint order, specified by the
  ///   z-index CSS style attribute.
  void updateChildren() {
    // Trivial case: remove all children.
    if (_childrenInHitTestOrder == null ||
        _childrenInHitTestOrder!.isEmpty) {
      if (_currentChildrenInRenderOrder == null ||
          _currentChildrenInRenderOrder!.isEmpty) {
        // A container element must not have been created when child list is empty.
        assert(_childContainerElement == null);
        _currentChildrenInRenderOrder = null;
        return;
      }

      // A container element must have been created when child list is not empty.
      assert(_childContainerElement != null);

      // Remove all children from this semantics object.
      final int len = _currentChildrenInRenderOrder!.length;
      for (int i = 0; i < len; i++) {
        owner._detachObject(_currentChildrenInRenderOrder![i].id);
      }
      _childContainerElement!.remove();
      _childContainerElement = null;
      _currentChildrenInRenderOrder = null;
      return;
    }

    // At this point it is guaranteed to have at least one child.
    final Int32List childrenInTraversalOrder = _childrenInTraversalOrder!;
    final Int32List childrenInHitTestOrder = _childrenInHitTestOrder!;
    final int childCount = childrenInHitTestOrder.length;
    final DomElement? containerElement = getOrCreateChildContainer();

    assert(childrenInTraversalOrder.length == childrenInHitTestOrder.length);

    // Always render in traversal order, because the accessibility traversal
    // is determined by the DOM order of elements.
    final List<SemanticsObject> childrenInRenderOrder = <SemanticsObject>[];
    for (int i = 0; i < childCount; i++) {
      childrenInRenderOrder.add(owner._semanticsTree[childrenInTraversalOrder[i]]!);
    }

    // The z-index determines hit testing. Technically, it also affects paint
    // order. However, this does not matter because our ARIA tree is invisible.
    // On top of that, it is a bad UI practice when hit test order does not match
    // paint order, because human eye must be able to predict hit test order
    // simply by looking at the UI (if a dialog is painted on top of a dismiss
    // barrier, then tapping on anything inside the dialog should not land on
    // the barrier).
    final bool zIndexMatters = childCount > 1;
    if (zIndexMatters) {
      for (int i = 0; i < childCount; i++) {
        final SemanticsObject child = owner._semanticsTree[childrenInHitTestOrder[i]]!;

        // Invert the z-index because hit-test order is inverted with respect to
        // paint order.
        child.element.style.zIndex = '${childCount - i}';
      }
    }

    // Trivial case: previous list was empty => just populate the container.
    if (_currentChildrenInRenderOrder == null ||
        _currentChildrenInRenderOrder!.isEmpty) {
      for (final SemanticsObject child in childrenInRenderOrder) {
        containerElement!.append(child.element);
        owner._attachObject(parent: this, child: child);
      }
      _currentChildrenInRenderOrder = childrenInRenderOrder;
      return;
    }

    // At this point it is guaranteed to have had a non-empty previous child list.
    final List<SemanticsObject> previousChildrenInRenderOrder = _currentChildrenInRenderOrder!;
    final int previousCount = previousChildrenInRenderOrder.length;

    // Both non-empty case.

    // Problem: child nodes have been added, removed, and/or reordered. On the
    //          web, many assistive technologies cannot track DOM elements
    //          moving around, losing focus. The best approach is to try to keep
    //          child elements as stable as possible.
    // Solution: find all common elements in both lists and record their indices
    //           in the old list (in the `intersectionIndicesOld` variable). The
    //           longest increases subsequence provides the longest chain of
    //           semantics nodes that didn't move relative to each other. Those
    //           nodes (represented by the `stationaryIds` variable) are kept
    //           stationary, while all others are moved/inserted/deleted around
    //           them. This gives the maximum node stability, and covers most
    //           use-cases, including scrolling in any direction, insertions,
    //           deletions, drag'n'drop, etc.

    // Indices into the old child list pointing at children that also exist in
    // the new child list.
    final List<int> intersectionIndicesOld = <int>[];

    int newIndex = 0;

    // The smallest of the two child list lengths.
    final int minLength = math.min(previousCount, childCount);

    // Scan forward until first discrepancy.
    while (newIndex < minLength &&
        previousChildrenInRenderOrder[newIndex] ==
            childrenInRenderOrder[newIndex]) {
      intersectionIndicesOld.add(newIndex);
      newIndex += 1;
    }

    // Trivial case: child lists are identical both in length and order => do nothing.
    if (previousCount == childrenInRenderOrder.length && newIndex == childCount) {
      return;
    }

    // If child lists are not identical, continue computing the intersection
    // between the two lists.
    while (newIndex < childCount) {
      for (int oldIndex = 0; oldIndex < previousCount; oldIndex += 1) {
        if (previousChildrenInRenderOrder[oldIndex] ==
            childrenInRenderOrder[newIndex]) {
          intersectionIndicesOld.add(oldIndex);
          break;
        }
      }
      newIndex += 1;
    }

    // The longest sub-sequence in the old list maximizes the number of children
    // that do not need to be moved.
    final List<int?> longestSequence = longestIncreasingSubsequence(intersectionIndicesOld);
    final List<int> stationaryIds = <int>[];
    for (int i = 0; i < longestSequence.length; i += 1) {
      stationaryIds.add(
        previousChildrenInRenderOrder[intersectionIndicesOld[longestSequence[i]!]].id
      );
    }

    // Remove children that are no longer in the list.
    for (int i = 0; i < previousCount; i++) {
      if (!intersectionIndicesOld.contains(i)) {
        // Child not in the intersection. Must be removed.
        final int childId = previousChildrenInRenderOrder[i].id;
        owner._detachObject(childId);
      }
    }

    DomElement? refNode;
    for (int i = childCount - 1; i >= 0; i -= 1) {
      final SemanticsObject child = childrenInRenderOrder[i];
      if (!stationaryIds.contains(child.id)) {
        if (refNode == null) {
          containerElement!.append(child.element);
        } else {
          containerElement!.insertBefore(child.element, refNode);
        }
        owner._attachObject(parent: this, child: child);
      } else {
        assert(child._parent == this);
      }
      refNode = child.element;
    }

    _currentChildrenInRenderOrder = childrenInRenderOrder;
  }

  /// Sets the `role` ARIA attribute.
  void setAriaRole(String ariaRoleName) {
    element.setAttribute('role', ariaRoleName);
  }

  /// The primary role of this node.
  ///
  /// The primary role is assigned by [updateSelf] based on the combination of
  /// semantics flags and actions.
  PrimaryRoleManager? primaryRole;

  PrimaryRole _getPrimaryRoleIdentifier() {
    // The most specific role should take precedence.
    if (isPlatformView) {
      return PrimaryRole.platformView;
    } else if (isTextField) {
      return PrimaryRole.textField;
    } else if (isIncrementable) {
      return PrimaryRole.incrementable;
    } else if (isVisualOnly) {
      return PrimaryRole.image;
    } else if (isCheckable) {
      return PrimaryRole.checkable;
    } else if (isButton) {
      return PrimaryRole.button;
    } else if (isScrollContainer) {
      return PrimaryRole.scrollable;
    } else if (scopesRoute) {
      return PrimaryRole.dialog;
    } else {
      return PrimaryRole.generic;
    }
  }

  PrimaryRoleManager _createPrimaryRole(PrimaryRole role) {
    return switch (role) {
      PrimaryRole.textField => TextField(this),
      PrimaryRole.scrollable => Scrollable(this),
      PrimaryRole.incrementable => Incrementable(this),
      PrimaryRole.button => Button(this),
      PrimaryRole.checkable => Checkable(this),
      PrimaryRole.dialog => Dialog(this),
      PrimaryRole.image => ImageRoleManager(this),
      PrimaryRole.platformView => PlatformViewRoleManager(this),
      PrimaryRole.generic => GenericRole(this),
    };
  }

  /// Detects the roles that this semantics object corresponds to and asks the
  /// respective role managers to update the DOM.
  void _updateRoles() {
    PrimaryRoleManager? currentPrimaryRole = primaryRole;
    final PrimaryRole roleId = _getPrimaryRoleIdentifier();

    if (currentPrimaryRole != null) {
      if (currentPrimaryRole.role == roleId) {
        // Already has a primary role assigned and the role is the same as before,
        // so simply perform an update.
        currentPrimaryRole.update();
        return;
      } else {
        // Role changed. This should be avoided as much as possible, but the
        // web engine will attempt a best with the switch by cleaning old ARIA
        // role data and start anew.
        currentPrimaryRole.dispose();
        currentPrimaryRole = null;
        primaryRole = null;
      }
    }

    // This handles two cases:
    //  * The node was just created and needs a primary role manager.
    //  * (Uncommon) the node changed its primary role, its previous primary
    //    role manager was disposed of, and now it needs a new one.
    if (currentPrimaryRole == null) {
      currentPrimaryRole = _createPrimaryRole(roleId);
      primaryRole = currentPrimaryRole;
      currentPrimaryRole.update();
    }
  }

  /// Whether the object represents an UI element with "increase" or "decrease"
  /// controls, e.g. a slider.
  ///
  /// Such objects are expressed in HTML using `<input type="range">`.
  bool get isIncrementable =>
      hasAction(ui.SemanticsAction.increase) ||
      hasAction(ui.SemanticsAction.decrease);

  /// Whether the object represents a button.
  bool get isButton => hasFlag(ui.SemanticsFlag.isButton);

  /// Represents a tappable or clickable widget, such as button, icon button,
  /// "hamburger" menu, etc.
  bool get isTappable => hasAction(ui.SemanticsAction.tap);

  bool get isCheckable =>
      hasFlag(ui.SemanticsFlag.hasCheckedState) ||
      hasFlag(ui.SemanticsFlag.hasToggledState);

  /// Role-specific adjustment of the vertical position of the child container.
  ///
  /// This is used, for example, by the [Scrollable] to compensate for the
  /// `scrollTop` offset in the DOM.
  ///
  /// This field must not be null.
  double verticalContainerAdjustment = 0.0;

  /// Role-specific adjustment of the horizontal position of the child
  /// container.
  ///
  /// This is used, for example, by the [Scrollable] to compensate for the
  /// `scrollLeft` offset in the DOM.
  ///
  /// This field must not be null.
  double horizontalContainerAdjustment = 0.0;

  /// Computes the size and position of [element] and, if this element
  /// [hasChildren], of [getOrCreateChildContainer].
  void recomputePositionAndSize() {
    element.style
      ..width = '${_rect!.width}px'
      ..height = '${_rect!.height}px';

    final DomElement? containerElement =
        hasChildren ? getOrCreateChildContainer() : null;

    final bool hasZeroRectOffset = _rect!.top == 0.0 && _rect!.left == 0.0;
    final Float32List? transform = _transform;
    final bool hasIdentityTransform =
        transform == null || isIdentityFloat32ListTransform(transform);

    if (hasZeroRectOffset &&
        hasIdentityTransform &&
        verticalContainerAdjustment == 0.0 &&
        horizontalContainerAdjustment == 0.0) {
      _clearSemanticElementTransform(element);
      if (containerElement != null) {
        _clearSemanticElementTransform(containerElement);
      }
      return;
    }

    late Matrix4 effectiveTransform;
    bool effectiveTransformIsIdentity = true;
    if (!hasZeroRectOffset) {
      if (transform == null) {
        final double left = _rect!.left;
        final double top = _rect!.top;
        effectiveTransform = Matrix4.translationValues(left, top, 0.0);
        effectiveTransformIsIdentity = left == 0.0 && top == 0.0;
      } else {
        // Clone to avoid mutating _transform.
        effectiveTransform = Matrix4.fromFloat32List(transform).clone()
          ..translate(_rect!.left, _rect!.top);
        effectiveTransformIsIdentity = effectiveTransform.isIdentity();
      }
    } else if (!hasIdentityTransform) {
      effectiveTransform = Matrix4.fromFloat32List(transform);
      effectiveTransformIsIdentity = false;
    }

    if (!effectiveTransformIsIdentity) {
      element.style
        ..transformOrigin = '0 0 0'
        ..transform = matrix4ToCssTransform(effectiveTransform);
    } else {
      _clearSemanticElementTransform(element);
    }

    if (containerElement != null) {
      if (!hasZeroRectOffset ||
          verticalContainerAdjustment != 0.0 ||
          horizontalContainerAdjustment != 0.0) {
        final double translateX = -_rect!.left + horizontalContainerAdjustment;
        final double translateY = -_rect!.top + verticalContainerAdjustment;
        containerElement.style
          ..top = '${translateY}px'
          ..left = '${translateX}px';
      } else {
        _clearSemanticElementTransform(containerElement);
      }
    }
  }

  /// Clears the transform on a semantic element as if an identity transform is
  /// applied.
  ///
  /// On macOS and iOS, VoiceOver requires `left=0; top=0` value to correctly
  /// handle traversal order.
  ///
  /// See https://github.com/flutter/flutter/issues/73347.
  static void _clearSemanticElementTransform(DomElement element) {
    element.style
      ..removeProperty('transform-origin')
      ..removeProperty('transform');
    if (isMacOrIOS) {
      element.style
        ..top = '0px'
        ..left = '0px';
    } else {
      element.style
        ..removeProperty('top')
        ..removeProperty('left');
    }
  }

  /// Recursively visits the tree rooted at `this` node in depth-first fashion.
  ///
  /// Calls the [callback] for `this` node, then for all of its descendants.
  void visitDepthFirst(void Function(SemanticsObject) callback) {
    callback(this);
    _currentChildrenInRenderOrder?.forEach((SemanticsObject child) {
      child.visitDepthFirst(callback);
    });
  }

  @override
  String toString() {
    String result = super.toString();
    assert(() {
      final String children = _childrenInTraversalOrder != null &&
              _childrenInTraversalOrder!.isNotEmpty
          ? '[${_childrenInTraversalOrder!.join(', ')}]'
          : '<empty>';
      result = '$runtimeType(#$id, children: $children)';
      return true;
    }());
    return result;
  }
}

/// Controls how pointer events and browser-detected gestures are treated by
/// the Web Engine.
enum AccessibilityMode {
  /// Flutter is not told whether the assistive technology is enabled or not.
  ///
  /// This is the default mode.
  ///
  /// In this mode a gesture recognition system is used that deduplicates
  /// gestures detected by Flutter with gestures detected by the browser.
  unknown,

  /// Flutter is told whether the assistive technology is enabled.
  known,
}

/// Called when the current [GestureMode] changes.
typedef GestureModeCallback = void Function(GestureMode mode);

/// The method used to detect user gestures.
enum GestureMode {
  /// Send pointer events to Flutter to detect gestures using framework-level
  /// gesture recognizers and gesture arenas.
  pointerEvents,

  /// Listen to browser-detected gestures and report them to the framework as
  /// [ui.SemanticsAction].
  browserGestures,
}

/// The current phase of the semantic update.
enum SemanticsUpdatePhase {
  /// No update is in progress.
  ///
  /// When the semantics owner receives an update, it enters the [updating]
  /// phase from the idle phase.
  idle,

  /// Updating individual [SemanticsObject] nodes by calling
  /// [RoleManager.update] and fixing parent-child relationships.
  ///
  /// After this phase is done, the owner enters the [postUpdate] phase.
  updating,

  /// Post-update callbacks are being called.
  ///
  /// At this point all nodes have been updated, the parent child hierarchy has
  /// been established, the DOM tree is in sync with the semantics tree, and
  /// [RoleManager.dispose] has been called on removed nodes.
  ///
  /// After this phase is done, the owner switches back to [idle].
  postUpdate,
}

/// The top-level service that manages everything semantics-related.
class EngineSemanticsOwner {
  EngineSemanticsOwner._() {
    registerHotRestartListener(() {
      _rootSemanticsElement?.remove();
    });
  }

  /// The singleton instance that manages semantics.
  static EngineSemanticsOwner get instance {
    return _instance ??= EngineSemanticsOwner._();
  }

  static EngineSemanticsOwner? _instance;

  /// Disables semantics and uninitializes the singleton [instance].
  ///
  /// Instances of [EngineSemanticsOwner] are no longer valid after calling this
  /// method. Using them will lead to undefined behavior. This method is only
  /// meant to be used for testing.
  static void debugResetSemantics() {
    if (_instance == null) {
      return;
    }
    _instance!.semanticsEnabled = false;
    _instance = null;
  }

  /// The current update phase of this semantics owner.
  SemanticsUpdatePhase get phase => _phase;
  SemanticsUpdatePhase _phase = SemanticsUpdatePhase.idle;

  final Map<int, SemanticsObject> _semanticsTree = <int, SemanticsObject>{};

  /// Map [SemanticsObject.id] to parent [SemanticsObject] it was attached to
  /// this frame.
  Map<int, SemanticsObject> _attachments = <int, SemanticsObject>{};

  /// Declares that the [child] must be attached to the [parent].
  ///
  /// Attachments take precedence over detachments (see [_detachObject]). This
  /// allows the same node to be detached from one parent in the tree and
  /// reattached to another parent.
  void _attachObject({required SemanticsObject parent, required SemanticsObject child}) {
    child._parent = parent;
    _attachments[child.id] = parent;
  }

  /// List of objects that were detached this frame.
  ///
  /// The objects in this list will be detached permanently unless they are
  /// reattached via the [_attachObject] method.
  List<SemanticsObject> _detachments = <SemanticsObject>[];

  /// Declares that the [SemanticsObject] with the given [id] was detached from
  /// its current parent object.
  ///
  /// The object will be detached permanently unless it is reattached via the
  /// [_attachObject] method.
  void _detachObject(int id) {
    final SemanticsObject? object = _semanticsTree[id];
    assert(object != null);
    if (object != null) {
      _detachments.add(object);
    }
  }

  /// Callbacks called after all objects in the tree have their properties
  /// populated and their sizes and locations computed.
  ///
  /// This list is reset to empty after all callbacks are called.
  List<ui.VoidCallback> _oneTimePostUpdateCallbacks = <ui.VoidCallback>[];

  /// Schedules a one-time callback to be called after all objects in the tree
  /// have their properties populated and their sizes and locations computed.
  void addOneTimePostUpdateCallback(ui.VoidCallback callback) {
    _oneTimePostUpdateCallbacks.add(callback);
  }

  /// Reconciles [_attachments] and [_detachments], and after that calls all
  /// the one-time callbacks scheduled via the [addOneTimePostUpdateCallback]
  /// method.
  void _finalizeTree() {
    for (final SemanticsObject detachmentRoot in _detachments) {
      // A detached node may or may not have some of its descendants reattached
      // elsewhere. Walk the descendant tree and find all descendants that were
      // reattached to a parent. Those descendants need to be removed.
      final List<SemanticsObject> removals = <SemanticsObject>[];
      detachmentRoot.visitDepthFirst((SemanticsObject node) {
        final SemanticsObject? parent = _attachments[node.id];
        if (parent == null) {
          // Was not reparented and is removed permanently from the tree.
          removals.add(node);
        } else {
          assert(node._parent == parent);
          assert(node.element.parentNode == parent._childContainerElement);
        }
      });

      for (final SemanticsObject removal in removals) {
        _semanticsTree.remove(removal.id);
        removal._parent = null;
        removal.element.remove();
      }
    }
    _detachments = <SemanticsObject>[];
    _attachments = <int, SemanticsObject>{};

    _phase = SemanticsUpdatePhase.postUpdate;
    try {
      if (_oneTimePostUpdateCallbacks.isNotEmpty) {
        for (final ui.VoidCallback callback in _oneTimePostUpdateCallbacks) {
          callback();
        }
        _oneTimePostUpdateCallbacks = <ui.VoidCallback>[];
      }
    } finally {
      _phase = SemanticsUpdatePhase.idle;
    }
  }

  /// Returns the entire semantics tree for testing.
  ///
  /// Works only in debug mode.
  Map<int, SemanticsObject>? get debugSemanticsTree {
    Map<int, SemanticsObject>? result;
    assert(() {
      result = _semanticsTree;
      return true;
    }());
    return result;
  }

  /// The top-level DOM element of the semantics DOM element tree.
  DomElement? _rootSemanticsElement;
  TimestampFunction _now = () => DateTime.now();

  void debugOverrideTimestampFunction(TimestampFunction value) {
    _now = value;
  }

  void debugResetTimestampFunction() {
    _now = () => DateTime.now();
  }

  final SemanticsHelper semanticsHelper = SemanticsHelper();

  /// Whether the user has requested that [updateSemantics] be called when the
  /// semantic contents of window changes.
  ///
  /// The [ui.PlatformDispatcher.onSemanticsEnabledChanged] callback is called
  /// whenever this value changes.
  ///
  /// This is separate from accessibility [mode], which controls how gestures
  /// are interpreted when this value is true.
  bool get semanticsEnabled => _semanticsEnabled;
  bool _semanticsEnabled = false;
  set semanticsEnabled(bool value) {
    if (value == _semanticsEnabled) {
      return;
    }
    final EngineAccessibilityFeatures original =
        EnginePlatformDispatcher.instance.configuration.accessibilityFeatures
        as EngineAccessibilityFeatures;
    final PlatformConfiguration newConfiguration =
        EnginePlatformDispatcher.instance.configuration.copyWith(
            accessibilityFeatures:
                original.copyWith(accessibleNavigation: value));
    EnginePlatformDispatcher.instance.configuration = newConfiguration;

    _semanticsEnabled = value;

    if (!_semanticsEnabled) {
      // Do not process browser events at all when semantics is explicitly
      // disabled. All gestures are handled by the framework-level gesture
      // recognizers from pointer events.
      if (_gestureMode != GestureMode.pointerEvents) {
        _gestureMode = GestureMode.pointerEvents;
        _notifyGestureModeListeners();
      }
      final List<int> keys = _semanticsTree.keys.toList();
      final int len = keys.length;
      for (int i = 0; i < len; i++) {
        _detachObject(keys[i]);
      }
      _finalizeTree();
      _rootSemanticsElement?.remove();
      _rootSemanticsElement = null;
      _gestureModeClock?.datetime = null;
    }
    EnginePlatformDispatcher.instance.updateSemanticsEnabled(_semanticsEnabled);
  }

  /// Controls how pointer events and browser-detected gestures are treated by
  /// the Web Engine.
  ///
  /// The default mode is [AccessibilityMode.unknown].
  AccessibilityMode mode = AccessibilityMode.unknown;

  /// Currently used [GestureMode].
  ///
  /// This value changes automatically depending on the incoming input events.
  /// Functionality that implements different strategies depending on this mode
  /// would use [addGestureModeListener] and [removeGestureModeListener] to get
  /// notifications about when the value of this field changes.
  GestureMode get gestureMode => _gestureMode;
  GestureMode _gestureMode = GestureMode.browserGestures;

  AlarmClock? _gestureModeClock;

  AlarmClock? _getGestureModeClock() {
    if (_gestureModeClock == null) {
      _gestureModeClock = AlarmClock(_now);
      _gestureModeClock!.callback = () {
        if (_gestureMode == GestureMode.browserGestures) {
          return;
        }

        _gestureMode = GestureMode.browserGestures;
        _notifyGestureModeListeners();
      };
    }
    return _gestureModeClock;
  }

  /// Disables browser gestures temporarily because pointer events were detected.
  ///
  /// This is used to deduplicate gestures detected by Flutter and gestures
  /// detected by the browser. Flutter-detected gestures have higher precedence.
  void _temporarilyDisableBrowserGestureMode() {
    const Duration kDebounceThreshold = Duration(milliseconds: 500);
    _getGestureModeClock()!.datetime = _now().add(kDebounceThreshold);
    if (_gestureMode != GestureMode.pointerEvents) {
      _gestureMode = GestureMode.pointerEvents;
      _notifyGestureModeListeners();
    }
  }

  /// Receives DOM events from the pointer event system to correlate with the
  /// semantics events; returns true if the event should be forwarded to the
  /// framework.
  ///
  /// The browser sends us both raw pointer events and gestures from
  /// [SemanticsObject.element]s. There could be three possibilities:
  ///
  /// 1. Assistive technology is enabled and Flutter knows that it is.
  /// 2. Assistive technology is disabled and Flutter knows that it isn't.
  /// 3. Flutter does not know whether an assistive technology is enabled.
  ///
  /// If [autoEnableOnTap] was called, this will automatically enable semantics
  /// if the user requests it.
  ///
  /// In the first case ignore raw pointer events and only interpret
  /// high-level gestures, e.g. "click".
  ///
  /// In the second case ignore high-level gestures and interpret the raw
  /// pointer events directly.
  ///
  /// Finally, in a mode when Flutter does not know if an assistive technology
  /// is enabled or not do a best-effort estimate which to respond to, raw
  /// pointer or high-level gestures. Avoid doing both because that will
  /// result in double-firing of event listeners, such as `onTap` on a button.
  /// The approach is to measure the distance between the last pointer
  /// event and a gesture event. If a gesture is receive "soon" after the last
  /// received pointer event (determined by a heuristic), it is debounced as it
  /// is likely that the gesture detected from the pointer even will do the
  /// right thing. However, if a standalone gesture is received, map it onto a
  /// [ui.SemanticsAction] to be processed by the framework.
  bool receiveGlobalEvent(DomEvent event) {
    // For pointer event reference see:
    //
    // https://developer.mozilla.org/en-US/docs/Web/API/Pointer_events
    const List<String> pointerEventTypes = <String>[
      'pointerdown',
      'pointermove',
      'pointerleave',
      'pointerup',
      'pointercancel',
      'touchstart',
      'touchend',
      'touchmove',
      'touchcancel',
      'mousedown',
      'mousemove',
      'mouseleave',
      'mouseup',
      'keyup',
      'keydown',
    ];

    if (pointerEventTypes.contains(event.type)) {
      _temporarilyDisableBrowserGestureMode();
    }

    return semanticsHelper.shouldEnableSemantics(event);
  }

  /// Callbacks called when the [GestureMode] changes.
  ///
  /// Callbacks are called synchronously. HTML DOM updates made in a callback
  /// take effect in the current animation frame and/or the current message loop
  /// event.
  final List<GestureModeCallback?> _gestureModeListeners = <GestureModeCallback?>[];

  /// Calls the [callback] every time the current [GestureMode] changes.
  ///
  /// The callback is called synchronously. HTML DOM updates made in the
  /// callback take effect in the current animation frame and/or the current
  /// message loop event.
  void addGestureModeListener(GestureModeCallback? callback) {
    _gestureModeListeners.add(callback);
  }

  /// Stops calling the [callback] when the [GestureMode] changes.
  ///
  /// The passed [callback] must be the exact same object as the one passed to
  /// [addGestureModeListener].
  void removeGestureModeListener(GestureModeCallback? callback) {
    assert(_gestureModeListeners.contains(callback));
    _gestureModeListeners.remove(callback);
  }

  void _notifyGestureModeListeners() {
    for (int i = 0; i < _gestureModeListeners.length; i++) {
      _gestureModeListeners[i]!(_gestureMode);
    }
  }

  /// Whether a gesture event of type [eventType] should be accepted as a
  /// semantic action.
  ///
  /// If [mode] is [AccessibilityMode.known] the gesture is always accepted if
  /// [semanticsEnabled] is `true`, and it is always rejected if
  /// [semanticsEnabled] is `false`.
  ///
  /// If [mode] is [AccessibilityMode.unknown] the gesture is accepted if it is
  /// not accompanied by pointer events. In the presence of pointer events,
  /// delegate to Flutter's gesture detection system to produce gestures.
  bool shouldAcceptBrowserGesture(String eventType) {
    if (mode == AccessibilityMode.known) {
      // Do not ignore accessibility gestures in known mode, unless semantics
      // is explicitly disabled.
      return semanticsEnabled;
    }

    const List<String> pointerDebouncedGestures = <String>[
      'click',
      'scroll',
    ];

    if (pointerDebouncedGestures.contains(eventType)) {
      return _gestureMode == GestureMode.browserGestures;
    }

    return false;
  }

  /// Looks up a [SemanticsObject] in the semantics tree by ID, or creates a new
  /// instance if it does not exist.
  SemanticsObject getOrCreateObject(int id) {
    SemanticsObject? object = _semanticsTree[id];
    if (object == null) {
      object = SemanticsObject(id, this);
      _semanticsTree[id] = object;
    }
    return object;
  }

  /// Updates the semantics tree from data in the [uiUpdate].
  void updateSemantics(ui.SemanticsUpdate uiUpdate) {
    if (!_semanticsEnabled) {
      if (ui_web.debugEmulateFlutterTesterEnvironment) {
        // Running Flutter widget tests in a fake environment. Don't enable
        // engine semantics. Test semantics trees violate invariants in ways
        // production implementation isn't built to handle. For example, tests
        // routinely reset semantics node IDs, which is messing up the update
        // process.
        return;
      } else {
        // Running a real app. Auto-enable engine semantics.
        semanticsHelper.dispose(); // placeholder no longer needed
        semanticsEnabled = true;
      }
    }

    _phase = SemanticsUpdatePhase.updating;
    final SemanticsUpdate update = uiUpdate as SemanticsUpdate;

    // First, update each object's information about itself. This information is
    // later used to fix the parent-child and sibling relationships between
    // objects.
    final List<SemanticsNodeUpdate> nodeUpdates = update._nodeUpdates!;
    for (final SemanticsNodeUpdate nodeUpdate in nodeUpdates) {
      final SemanticsObject object = getOrCreateObject(nodeUpdate.id);
      object.updateSelf(nodeUpdate);
    }

    // Second, fix the tree structure. This is moved out into its own loop,
    // because each object's own information must be updated first.
    for (final SemanticsNodeUpdate nodeUpdate in nodeUpdates) {
      final SemanticsObject object = _semanticsTree[nodeUpdate.id]!;
      object.updateChildren();
      object._dirtyFields = 0;
    }

    if (_rootSemanticsElement == null) {
      final SemanticsObject root = _semanticsTree[0]!;
      _rootSemanticsElement = root.element;
      flutterViewEmbedder.semanticsHostElement!.append(root.element);
    }

    _finalizeTree();

    assert(_semanticsTree.containsKey(0)); // must contain root node
    assert(() {
      // Validate that the node map only contains live elements, i.e. descendants
      // of the root node. If a node is not reachable from the root, it should
      // have been removed from the map.
      final List<int> liveIds = <int>[];
      final SemanticsObject root = _semanticsTree[0]!;
      root.visitDepthFirst((SemanticsObject child) {
        liveIds.add(child.id);
      });
      assert(
        _semanticsTree.keys.every(liveIds.contains),
        'The semantics node map is inconsistent:\n'
        '  Nodes in tree: [${liveIds.join(', ')}]\n'
        '  Nodes in map : [${_semanticsTree.keys.join(', ')}]'
      );

      // Validate that each node in the final tree is self-consistent.
      _semanticsTree.forEach((int? id, SemanticsObject object) {
        assert(id == object.id);

        // Dirty fields should be cleared after the tree has been finalized.
        assert(object._dirtyFields == 0);

        // Make sure a child container is created only when there are children.
        assert(object._childContainerElement == null || object.hasChildren);

        // Ensure child ID list is consistent with the parent-child
        // relationship of the semantics tree.
        if (object._childrenInTraversalOrder != null) {
          for (final int childId in object._childrenInTraversalOrder!) {
            final SemanticsObject? child = _semanticsTree[childId];
            if (child == null) {
              throw AssertionError('Child #$childId is missing in the tree.');
            }
            if (child._parent == null) {
              throw AssertionError(
                  'Child #$childId of parent #${object.id} has null parent '
                  'reference.');
            }
            if (!identical(child._parent, object)) {
              throw AssertionError(
                  'Parent #${object.id} has child #$childId. However, the '
                  'child is attached to #${child._parent!.id}.');
            }
          }
        }
      });

      // Validate that all updates were applied
      for (final SemanticsNodeUpdate update in nodeUpdates) {
        // Node was added to the tree.
        assert(_semanticsTree.containsKey(update.id));
      }

      // Verify that `update._nodeUpdates` has not changed.
      assert(identical(update._nodeUpdates, nodeUpdates));

      return true;
    }());
  }
}

/// Computes the [longest increasing subsequence](http://en.wikipedia.org/wiki/Longest_increasing_subsequence).
///
/// Returns list of indices (rather than values) into [list].
///
/// Complexity: n*log(n)
List<int> longestIncreasingSubsequence(List<int> list) {
  final int len = list.length;
  final List<int> predecessors = <int>[];
  final List<int> mins = <int>[0];
  int longest = 0;
  for (int i = 0; i < len; i++) {
    // Binary search for the largest positive `j ≤ longest`
    // such that `list[mins[j]] < list[i]`
    final int elem = list[i];
    int lo = 1;
    int hi = longest;
    while (lo <= hi) {
      final int mid = (lo + hi) ~/ 2;
      if (list[mins[mid]] < elem) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    // After searching, `lo` is 1 greater than the
    // length of the longest prefix of `list[i]`
    final int expansionIndex = lo;
    // The predecessor of `list[i]` is the last index of
    // the subsequence of length `newLongest - 1`
    predecessors.add(mins[expansionIndex - 1]);
    if (expansionIndex >= mins.length) {
      mins.add(i);
    } else {
      mins[expansionIndex] = i;
    }
    if (expansionIndex > longest) {
      // Record the longest subsequence found so far.
      longest = expansionIndex;
    }
  }
  // Reconstruct the longest subsequence
  final List<int> seq = List<int>.filled(longest, 0);
  int k = mins[longest];
  for (int i = longest - 1; i >= 0; i--) {
    seq[i] = k;
    k = predecessors[k];
  }
  return seq;
}

/// States that a [ui.SemanticsNode] can have.
///
/// SemanticsNodes can be in three distinct states (enabled, disabled,
/// no opinion).
enum EnabledState {
  /// Flag [ui.SemanticsFlag.hasEnabledState] is not set.
  ///
  /// The node does not have enabled/disabled state.
  noOpinion,

  /// Flag [ui.SemanticsFlag.hasEnabledState] and [ui.SemanticsFlag.isEnabled]
  /// are set.
  ///
  /// The node is enabled.
  enabled,

  /// Flag [ui.SemanticsFlag.hasEnabledState] is set and
  /// [ui.SemanticsFlag.isEnabled] is not set.
  ///
  /// The node is disabled.
  disabled,
}
