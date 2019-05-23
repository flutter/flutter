// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'binding.dart';
import 'focus_manager.dart';
import 'framework.dart';

/// Creates actions for use in defining shortcuts.
///
/// Used by clients of [ShortcutMap] to define shortcut maps.
typedef ActionFactory = Action Function();

/// A class representing a particular configuration of an action.
///
/// This class is what a key mapping in a [ShortcutMap] maps to, and is used
/// by the [ActionDispatcher] to look up an action and invoke it, giving it this
/// object.
///
/// If this tag is not [enabled], then its associated action will not be
/// invoked if requested.
class ActionTag extends Diagnosticable {
  /// A const constructor for an [ActionTag].
  ///
  /// The [name] argument must not be null.
  const ActionTag(this.name, {this.enabled = true})
      : assert(name != null),
        assert(enabled != null);

  /// The name of the action this tag labels.
  final String name;

  /// Returns true if the associated action is able to be executed in the
  /// current environment.
  ///
  /// Returns true by default.
  final bool enabled;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('name', name));
  }
}

/// Base class for actions.
///
/// As the name implies, an [Action] is an action or command to be performed.
/// They are typically invoked as a result of a user action, such as a keyboard
/// shortcut.
///
/// The [ActionDispatcher] can invoke actions on the primary focus, or without
/// regard for focus.
abstract class Action extends Diagnosticable {
  /// A const constructor for an [Action].
  ///
  /// The [name] parameter must not be null.
  Action(String name) : _name = name;

  /// The unique name for this action.
  String get name => _name ?? runtimeType.toString();
  final String _name;

  /// Called when the action is to be performed.
  ///
  /// This is called by the [ActionDispatcher] when an action is accepted by a
  /// [FocusNode] by returning true from its `onAction` callback, or when an
  /// action is invoked using [ActionDispatcher.invokeAction].
  ///
  /// This method is only meant to be invoked by an [ActionDispatcher], or by
  /// subclasses.
  ///
  /// Actions invoked directly with [ActionDispatcher.invokeAction] may receive a
  /// null `node`. If the information available from a focus node is
  /// needed in the action, use [ActionDispatcher.invokeFocusedAction] instead.
  @protected
  @mustCallSuper
  void invoke(FocusNode node, covariant ActionTag tag);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('name', name));
  }
}

/// The signature of a callback accepted by [CallbackAction].
typedef ActionCallback = void Function(FocusNode node, ActionTag tag);

/// An [Action] that takes a callback in order to configure it without having to
/// subclass it.
class CallbackAction extends Action {
  /// A const constructor for an [Action].
  ///
  /// The [name] parameter must not be null.
  CallbackAction({String name, @required this.onInvoke}) : super(name);

  /// The callback to be called when invoked.
  @protected
  final ActionCallback onInvoke;

  @override
  void invoke(FocusNode node, ActionTag tag) => onInvoke?.call(node, tag);
}

/// An action manager that simply invokes the actions given to it.
class ActionDispatcher extends Diagnosticable {
  /// Const constructor so that subclasses may be const.
  ActionDispatcher({Map<String, ActionFactory> actions = const <String, ActionFactory>{}})
      : assert(actions != null),
        _actions = actions;

  /// Invokes the given action on a global basis, without regard for the
  /// currently focused node in the focus tree.
  ///
  /// Actions invoked globally may receive a null `node`.
  Action invokeAction(ActionTag tag, {FocusNode node}) {
    // Create an Action instance using the registered factory, if any.
    final Action action = _actions[tag.name]?.call();
    if (action != null && tag.enabled) {
      action.invoke(node, tag);
    }
    return action;
  }

  /// Invokes the given action after looking up the name of the `tag` in
  /// its registry of actions.
  Action invokeFocusedAction(ActionTag tag) {
    return invokeAction(tag, node: WidgetsBinding.instance.focusManager.primaryFocus);
  }

  final Map<String, ActionFactory> _actions;

  /// Registers an action factory for generating an action by the name `name`.
  void registerAction(String name, ActionFactory factory) {
    _actions[name] = factory;
  }

  /// Removes a given action from the registry.
  void removeAction(String name) {
    _actions.remove(name);
  }

  /// Returns true if an action by the given name is registered.
  bool hasAction(String name) => _actions.containsKey(name);
}

/// A widget that establishes an [ActionDispatcher] to be used by its descendants
/// when invoking an [Action].
///
/// See also:
///
///   * [ActionDispatcher], the object that this widget uses to manage actions.
///   * [Action], a class for containing and defining an invocation of a user
///     action.
///   * [UndoableActionManager], the object that this widget uses to manage
///     actions.
///   * [UndoableAction], a class for containing and defining an invocation of
///     an undoable user action.
class Actions extends InheritedWidget {
  /// Creates a ActionManager object.
  ///
  /// The [child] argument must not be null.
  const Actions({
    Key key,
    this.dispatcher,
    @required Widget child,
  }) : super(key: key, child: child);

  /// The [ActionDispatcher] object that actually invokes actions.
  ///
  /// This is what is returned from [Actions.of].
  final ActionDispatcher dispatcher;

  /// Returns the [ActionDispatcher] that most tightly encloses the given
  /// [BuildContext].
  ///
  /// The [context] argument must not be null.
  static ActionDispatcher of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    final Actions inherited = context.inheritFromWidgetOfExactType(Actions);
    assert(() {
      if (nullOk) {
        return true;
      }
      if (inherited == null) {
        throw FlutterError('Unable to find a DefaultFocusTraversal widget in the context.\n'
            'DefaultFocusTraversal.of() was called with a context that does not contain a '
            'DefaultFocusTraversal.\n'
            'No DefaultFocusTraversal ancestor could be found starting from the context that was '
            'passed to DefaultFocusTraversal.of(). This can happen because there is not a '
            'WidgetsApp or MaterialApp widget (those widgets introduce a DefaultFocusTraversal), '
            'or it can happen if the context comes from a widget above those widgets.\n'
            'The context used was:\n'
            '  $context');
      }
      return true;
    }());
    return inherited?.dispatcher;
  }

  @override
  bool updateShouldNotify(Actions oldWidget) => dispatcher != oldWidget.dispatcher;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ActionDispatcher>('manager', dispatcher));
  }
}
