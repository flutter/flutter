// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/semantics.dart';
import 'package:ui/src/engine/vector_math.dart';
import 'package:ui/ui.dart' as ui;

import '../../common/matchers.dart';

/// A convenience wrapper of the semantics API for building and inspecting the
/// semantics tree in unit tests.
class SemanticsTester {
  SemanticsTester(this.owner);

  final EngineSemanticsOwner owner;
  final List<SemanticsNodeUpdate> _nodeUpdates = <SemanticsNodeUpdate>[];

  /// Updates one semantics node.
  ///
  /// Provides reasonable defaults for the missing attributes, and conveniences
  /// for specifying flags, such as [isTextField].
  SemanticsNodeUpdate updateNode({
    required int id,
    ui.SemanticsFlags? flags,
    // Actions
    int actions = 0,
    bool? hasTap,
    bool? hasLongPress,
    bool? hasScrollLeft,
    bool? hasScrollRight,
    bool? hasScrollUp,
    bool? hasScrollDown,
    bool? hasIncrease,
    bool? hasDecrease,
    bool? hasShowOnScreen,
    bool? hasMoveCursorForwardByCharacter,
    bool? hasMoveCursorBackwardByCharacter,
    bool? hasSetSelection,
    bool? hasCopy,
    bool? hasCut,
    bool? hasPaste,
    bool? hasDidGainAccessibilityFocus,
    bool? hasDidLoseAccessibilityFocus,
    bool? hasFocus,
    bool? hasCustomAction,
    bool? hasDismiss,
    bool? hasMoveCursorForwardByWord,
    bool? hasMoveCursorBackwardByWord,
    bool? hasSetText,

    // Other attributes
    int? maxValueLength,
    int? currentValueLength,
    int? textSelectionBase,
    int? textSelectionExtent,
    int? platformViewId,
    int? scrollChildren,
    int? scrollIndex,
    int? traversalParent,
    double? scrollPosition,
    double? scrollExtentMax,
    double? scrollExtentMin,
    ui.Rect? rect,
    String? identifier,
    String? label,
    List<ui.StringAttribute>? labelAttributes,
    String? hint,
    List<ui.StringAttribute>? hintAttributes,
    String? value,
    List<ui.StringAttribute>? valueAttributes,
    String? increasedValue,
    List<ui.StringAttribute>? increasedValueAttributes,
    String? decreasedValue,
    List<ui.StringAttribute>? decreasedValueAttributes,
    String? tooltip,
    ui.TextDirection? textDirection,
    Float64List? transform,
    Float64List? hitTestTransform,
    Int32List? additionalActions,
    List<SemanticsNodeUpdate>? children,
    int? headingLevel,
    String? linkUrl,
    ui.SemanticsRole? role,
    List<String>? controlsNodes,
    ui.SemanticsValidationResult validationResult = ui.SemanticsValidationResult.none,
    ui.SemanticsHitTestBehavior hitTestBehavior = ui.SemanticsHitTestBehavior.defer,
    ui.SemanticsInputType inputType = ui.SemanticsInputType.none,
    ui.Locale? locale,
    String? minValue,
    String? maxValue,
  }) {
    // Actions
    if (hasTap ?? false) {
      actions |= ui.SemanticsAction.tap.index;
    }
    if (hasLongPress ?? false) {
      actions |= ui.SemanticsAction.longPress.index;
    }
    if (hasScrollLeft ?? false) {
      actions |= ui.SemanticsAction.scrollLeft.index;
    }
    if (hasScrollRight ?? false) {
      actions |= ui.SemanticsAction.scrollRight.index;
    }
    if (hasScrollUp ?? false) {
      actions |= ui.SemanticsAction.scrollUp.index;
    }
    if (hasScrollDown ?? false) {
      actions |= ui.SemanticsAction.scrollDown.index;
    }
    if (hasIncrease ?? false) {
      actions |= ui.SemanticsAction.increase.index;
    }
    if (hasDecrease ?? false) {
      actions |= ui.SemanticsAction.decrease.index;
    }
    if (hasShowOnScreen ?? false) {
      actions |= ui.SemanticsAction.showOnScreen.index;
    }
    if (hasMoveCursorForwardByCharacter ?? false) {
      actions |= ui.SemanticsAction.moveCursorForwardByCharacter.index;
    }
    if (hasMoveCursorBackwardByCharacter ?? false) {
      actions |= ui.SemanticsAction.moveCursorBackwardByCharacter.index;
    }
    if (hasSetSelection ?? false) {
      actions |= ui.SemanticsAction.setSelection.index;
    }
    if (hasCopy ?? false) {
      actions |= ui.SemanticsAction.copy.index;
    }
    if (hasCut ?? false) {
      actions |= ui.SemanticsAction.cut.index;
    }
    if (hasPaste ?? false) {
      actions |= ui.SemanticsAction.paste.index;
    }
    if (hasDidGainAccessibilityFocus ?? false) {
      actions |= ui.SemanticsAction.didGainAccessibilityFocus.index;
    }
    if (hasDidLoseAccessibilityFocus ?? false) {
      actions |= ui.SemanticsAction.didLoseAccessibilityFocus.index;
    }
    if (hasFocus ?? false) {
      actions |= ui.SemanticsAction.focus.index;
    }
    if (hasCustomAction ?? false) {
      actions |= ui.SemanticsAction.customAction.index;
    }
    if (hasDismiss ?? false) {
      actions |= ui.SemanticsAction.dismiss.index;
    }
    if (hasMoveCursorForwardByWord ?? false) {
      actions |= ui.SemanticsAction.moveCursorForwardByWord.index;
    }
    if (hasMoveCursorBackwardByWord ?? false) {
      actions |= ui.SemanticsAction.moveCursorBackwardByWord.index;
    }
    if (hasSetText ?? false) {
      actions |= ui.SemanticsAction.setText.index;
    }

    // Other attributes
    ui.Rect childRect(SemanticsNodeUpdate child) {
      return Matrix4.fromFloat32List(child.transform).transformRect(child.rect);
    }

    // If a rect is not provided, generate one than covers all children.
    ui.Rect effectiveRect = rect ?? ui.Rect.zero;
    if (children != null && children.isNotEmpty) {
      effectiveRect = childRect(children.first);
      for (final SemanticsNodeUpdate child in children.skip(1)) {
        effectiveRect = effectiveRect.expandToInclude(childRect(child));
      }
    }

    final childIds = Int32List(children?.length ?? 0);
    if (children != null) {
      for (var i = 0; i < children.length; i++) {
        childIds[i] = children[i].id;
      }
    }

    final update = SemanticsNodeUpdate(
      id: id,
      flags: flags ?? ui.SemanticsFlags.none,
      actions: actions,
      maxValueLength: maxValueLength ?? 0,
      currentValueLength: currentValueLength ?? 0,
      textSelectionBase: textSelectionBase ?? 0,
      textSelectionExtent: textSelectionExtent ?? 0,
      platformViewId: platformViewId ?? -1,
      scrollChildren: scrollChildren ?? 0,
      scrollIndex: scrollIndex ?? 0,
      traversalParent: traversalParent ?? -1,
      scrollPosition: scrollPosition ?? 0,
      scrollExtentMax: scrollExtentMax ?? 0,
      scrollExtentMin: scrollExtentMin ?? 0,
      rect: effectiveRect,
      identifier: identifier ?? '',
      label: label ?? '',
      labelAttributes: labelAttributes ?? const <ui.StringAttribute>[],
      hint: hint ?? '',
      hintAttributes: hintAttributes ?? const <ui.StringAttribute>[],
      value: value ?? '',
      valueAttributes: valueAttributes ?? const <ui.StringAttribute>[],
      increasedValue: increasedValue ?? '',
      increasedValueAttributes: increasedValueAttributes ?? const <ui.StringAttribute>[],
      decreasedValue: decreasedValue ?? '',
      decreasedValueAttributes: decreasedValueAttributes ?? const <ui.StringAttribute>[],
      tooltip: tooltip ?? '',
      transform: transform != null ? toMatrix32(transform) : Matrix4.identity().storage,
      hitTestTransform: hitTestTransform != null
          ? toMatrix32(hitTestTransform)
          : Matrix4.identity().storage,
      childrenInTraversalOrder: childIds,
      childrenInHitTestOrder: childIds,
      additionalActions: additionalActions ?? Int32List(0),
      headingLevel: headingLevel ?? 0,
      linkUrl: linkUrl,
      role: role ?? ui.SemanticsRole.none,
      controlsNodes: controlsNodes,
      validationResult: validationResult,
      hitTestBehavior: hitTestBehavior,
      inputType: inputType,
      locale: locale,
      minValue: minValue ?? '0',
      maxValue: maxValue ?? '0',
    );
    _nodeUpdates.add(update);
    return update;
  }

  /// Updates the HTML tree from semantics updates accumulated by this builder.
  ///
  /// This builder forgets previous updates and may be reused in future updates.
  Map<int, SemanticsObject> apply() {
    owner.updateSemantics(SemanticsUpdate(nodeUpdates: _nodeUpdates));
    _nodeUpdates.clear();
    return owner.debugSemanticsTree!;
  }

  /// Locates the semantics object with the given [id].
  SemanticsObject getSemanticsObject(int id) {
    return owner.debugSemanticsTree![id]!;
  }

  /// Locates the [SemanticTextField] role of the semantics object with the give [id].
  SemanticTextField getTextField(int id) {
    return getSemanticsObject(id).semanticRole! as SemanticTextField;
  }

  void expectSemantics(String semanticsHtml) {
    expectSemanticsTree(owner, semanticsHtml);
  }
}

/// Verifies the HTML structure of the current semantics tree.
void expectSemanticsTree(EngineSemanticsOwner owner, String semanticsHtml) {
  expect(owner.semanticsHost.children.single, hasHtml(semanticsHtml));
}

/// Finds the first HTML element in the semantics tree used for scrolling.
DomElement findScrollable(EngineSemanticsOwner owner) {
  return owner.semanticsHost.querySelectorAll('flt-semantics').singleWhere((DomElement? element) {
    return element!.style.overflow == 'hidden' ||
        element.style.overflowY == 'scroll' ||
        element.style.overflowX == 'scroll';
  });
}

/// Logs semantics actions dispatched to [ui.PlatformDispatcher].
class SemanticsActionLogger {
  SemanticsActionLogger() {
    _idLogController = StreamController<int>();
    _actionLogController = StreamController<ui.SemanticsAction>();
    _idLog = _idLogController.stream.asBroadcastStream();
    _actionLog = _actionLogController.stream.asBroadcastStream();

    // The browser kicks us out of the test zone when the browser event happens.
    // We memorize the test zone so we can call expect when the callback is
    // fired.
    final Zone testZone = Zone.current;

    ui.PlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      _idLogController.add(event.nodeId);
      _actionLogController.add(event.type);
      testZone.run(() {
        expect(event.arguments, null);
      });
    };
  }

  late StreamController<int> _idLogController;
  late StreamController<ui.SemanticsAction> _actionLogController;

  /// Semantics object ids that dispatched the actions.
  Stream<int> get idLog => _idLog;
  late Stream<int> _idLog;

  /// The actions that were dispatched to [ui.PlatformDispatcher].
  Stream<ui.SemanticsAction> get actionLog => _actionLog;
  late Stream<ui.SemanticsAction> _actionLog;
}

extension SemanticRoleExtension on SemanticRole {
  /// Types of semantics behaviors used by this role.
  List<Type> get debugSemanticBehaviorTypes =>
      behaviors?.map((behavior) => behavior.runtimeType).toList() ?? const <Type>[];
}
