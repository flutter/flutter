// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Base class for actions.
///
/// As the name implies, an [Action] is an action or command to be performed.
/// They are typically invoked as a result of a user action, such as a keyboard
/// shortcut.
///
/// The [ActionManager] can invoke actions on the primary focus, or without
/// regard for focus.
abstract class Action {
  /// A const constructor for [Action].
  ///
  /// The [name] parameter must not be null.
  const Action({@required this.name})
      : assert(name != null);

  /// The unique name for this action.
  final String name;

  /// Returns a read-only view of the properties set on this action.
  ///
  /// Modifications of the returned `Map` will not be reflected in the internal
  /// properties of the [Action].
  Map<String, dynamic> get properties;

  /// Returns true if this action currently can be invoked with [invoke].
  bool get enabled;

  /// Called when the action is to be performed.
  ///
  /// This is called by the [ActionManager] when an action is authorized by an
  /// action handler (typically an `onAction` handler on a widget or
  /// [FocusNode]).
  ///
  /// This method is only meant to be invoked by an [ActionManager], and by
  /// subclasses.
  @protected
  void invoke();

  /// Allows a widget to endorse invocation of an action in the given build
  /// context.
  ///
  /// This will cause the [ActionManager] to invoke the given [Action].
  void endorseInvocation(BuildContext context);

  @override
  bool operator==(dynamic other) {
    if (runtimeType != other.runtimeType)
      return false;
    if (identical(this, other))
      return true;
    return name == other.name && properties == other.properties;
  }

  @override
  int get hashCode => hashValues(name, properties);
}

/// An action that can be undone.
abstract class UndoableAction extends Action {
  /// A const constructor to [UndoableAction].
  ///
  /// The [name] parameter must not be null.
  const UndoableAction({@required String name}) : assert(name != null), super(name:name);

  /// Returns true if the data model can be returned to the state it was in previous to this action being executed.
  bool get undoable;

  /// Reverts the data model to the state before this command executed.
  void undo();
}

/// A singleton that manages the invocation of actions.
class ActionManager {
  /// Constructs a new [ActionManager].
  ///
  /// The [maxUndoLevels] argument must not be null.
  ActionManager({int maxUndoLevels = _defaultMaxUndoLevels}) : assert(maxUndoLevels != null), _maxUndoLevels = maxUndoLevels;

  // A stack of actions that have been performed.
  List<UndoableAction> _completedActions;
  List<UndoableAction> _undoneActions;

  static const int _defaultMaxUndoLevels = 1000;

  /// The maximum number of undo levels allowed.
  ///
  /// If this value is set to a value smaller than the number of completed
  /// actions, then the stack of completed actions is truncated to only include
  /// the last [maxUndoLevels] actions.
  int get maxUndoLevels => _maxUndoLevels;
  int _maxUndoLevels;
  set maxUndoLevels(int value) {
    _maxUndoLevels = value;
    _pruneActions();
  }

  /// Invokes the given action on a global basis, without regard for the
  /// currently focused node in the focus tree.
  void invokeAction(UndoableAction action) {
    action.invoke();
    _completedActions.add(action);
  }

  void _pruneActions() {
    if (_completedActions.length > _maxUndoLevels) {
      _completedActions = _completedActions.sublist(_completedActions.length - _maxUndoLevels, _completedActions.length);
    }
  }

  /// Invokes the given action by asking each of the nodes in the focus tree if
  /// they would like to invoke it.
  void invokeFocusedAction(UndoableAction action) {
    // Ask the focus manager to pass the given action up the focus tree.
  }

  /// Returns true if there is an action on the stack that can be undone.
  bool get canUndo => _completedActions.isNotEmpty ? _completedActions.last.undoable : false;

  /// Returns true if an action that has been undone can be re-invoked.
  bool get canRedo => _undoneActions.isNotEmpty ? _undoneActions.last.enabled : false;

  /// Undoes the last action executed if possible.
  ///
  /// Returns true if the action was successfully undone.
  bool undo() {
    if (!canUndo) {
      return false;
    }
    _undoneActions.add(_completedActions.removeLast());
    return true;
  }

  /// Re-invokes a previously undone action, if possible.
  ///
  /// Returns true if the action was successfully invoked.
  bool redo() {
    if (!canRedo) {
      return false;
    }
    _completedActions.add(_undoneActions.removeLast());
    return true;
  }
}
