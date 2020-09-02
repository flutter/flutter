// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'media_query.dart';
import 'shortcuts.dart';

// BuildContext/Element doesn't have a parent accessor, but it can be
// simulated with visitAncestorElements. _getParent is needed because
// context.getElementForInheritedWidgetOfExactType will return itself if it
// happens to be of the correct type. getParent should be O(1), since we
// always return false at the first ancestor.
BuildContext _getParent(BuildContext context) {
  BuildContext parent;
  context.visitAncestorElements((Element ancestor) {
    parent = ancestor;
    return false;
  });
  return parent;
}

/// A class representing a particular configuration of an [Action].
///
/// This class is what the [Shortcuts.shortcuts] map has as values, and is used
/// by an [ActionDispatcher] to look up an action and invoke it, giving it this
/// object to extract configuration information from.
///
/// See also:
///
///  * [Actions.invoke], which invokes the action associated with a specified
///    [Intent] using the [Actions] widget that most tightly encloses the given
///    [BuildContext].
@immutable
class Intent with Diagnosticable {
  /// A const constructor for an [Intent].
  const Intent();

  /// An intent that can't be mapped to an action.
  ///
  /// This Intent is mapped to an action in the [WidgetsApp] that does nothing,
  /// so that it can be bound to a key in a [Shortcuts] widget in order to
  /// disable a key binding made above it in the hierarchy.
  static const DoNothingIntent doNothing = DoNothingIntent._();
}

/// The kind of callback that an [Action] uses to notify of changes to the
/// action's state.
///
/// To register an action listener, call [Action.addActionListener].
typedef ActionListenerCallback = void Function(Action<Intent> action);

/// Base class for actions.
///
/// As the name implies, an [Action] is an action or command to be performed.
/// They are typically invoked as a result of a user action, such as a keyboard
/// shortcut in a [Shortcuts] widget, which is used to look up an [Intent],
/// which is given to an [ActionDispatcher] to map the [Intent] to an [Action]
/// and invoke it.
///
/// The [ActionDispatcher] can invoke an [Action] on the primary focus, or
/// without regard for focus.
///
/// See also:
///
///  * [Shortcuts], which is a widget that contains a key map, in which it looks
///    up key combinations in order to invoke actions.
///  * [Actions], which is a widget that defines a map of [Intent] to [Action]
///    and allows redefining of actions for its descendants.
///  * [ActionDispatcher], a class that takes an [Action] and invokes it, passing
///    a given [Intent].
abstract class Action<T extends Intent> with Diagnosticable {
  final ObserverList<ActionListenerCallback> _listeners = ObserverList<ActionListenerCallback>();

  /// Gets the type of intent this action responds to.
  Type get intentType => T;

  /// Returns true if the action is enabled and is ready to be invoked.
  ///
  /// This will be called by the [ActionDispatcher] before attempting to invoke
  /// the action.
  ///
  /// If the enabled state changes, overriding subclasses must call
  /// [notifyActionListeners] to notify any listeners of the change.
  bool isEnabled(covariant T intent) => true;

  /// Called when the action is to be performed.
  ///
  /// This is called by the [ActionDispatcher] when an action is invoked via
  /// [Actions.invoke], or when an action is invoked using
  /// [ActionDispatcher.invokeAction] directly.
  ///
  /// This method is only meant to be invoked by an [ActionDispatcher], or by
  /// its subclasses, and only when [isEnabled] is true.
  ///
  /// When overriding this method, the returned value can be any Object, but
  /// changing the return type of the override to match the type of the returned
  /// value provides more type safety.
  ///
  /// For instance, if your override of `invoke` returns an `int`, then define
  /// it like so:
  ///
  /// ```dart
  /// class IncrementIntent extends Intent {
  ///   const IncrementIntent({this.index});
  ///
  ///   final int index;
  /// }
  ///
  /// class MyIncrementAction extends Action<IncrementIntent> {
  ///   @override
  ///   int invoke(IncrementIntent intent) {
  ///     return intent.index + 1;
  ///   }
  /// }
  /// ```
  @protected
  Object invoke(covariant T intent);

  /// Register a callback to listen for changes to the state of this action.
  ///
  /// If you call this, you must call [removeActionListener] a matching number
  /// of times, or memory leaks will occur. To help manage this and avoid memory
  /// leaks, use of the [ActionListener] widget to register and unregister your
  /// listener appropriately is highly recommended.
  ///
  /// {@template flutter.widgets.actions.multipleAdds}
  /// If a listener had been added twice, and is removed once during an
  /// iteration (i.e. in response to a notification), it will still be called
  /// again. If, on the other hand, it is removed as many times as it was
  /// registered, then it will no longer be called. This odd behavior is the
  /// result of the [Action] not being able to determine which listener
  /// is being removed, since they are identical, and therefore conservatively
  /// still calling all the listeners when it knows that any are still
  /// registered.
  ///
  /// This surprising behavior can be unexpectedly observed when registering a
  /// listener on two separate objects which are both forwarding all
  /// registrations to a common upstream object.
  /// {@endtemplate}
  @mustCallSuper
  void addActionListener(ActionListenerCallback listener) => _listeners.add(listener);

  /// Remove a previously registered closure from the list of closures that are
  /// notified when the object changes.
  ///
  /// If the given listener is not registered, the call is ignored.
  ///
  /// If you call [addActionListener], you must call this method a matching
  /// number of times, or memory leaks will occur. To help manage this and avoid
  /// memory leaks, use of the [ActionListener] widget to register and
  /// unregister your listener appropriately is highly recommended.
  ///
  /// {@macro flutter.widgets.actions.multipleAdds}
  @mustCallSuper
  void removeActionListener(ActionListenerCallback listener) => _listeners.remove(listener);

  /// Call all the registered listeners.
  ///
  /// Subclasses should call this method whenever the object changes, to notify
  /// any clients the object may have changed. Listeners that are added during this
  /// iteration will not be visited. Listeners that are removed during this
  /// iteration will not be visited after they are removed.
  ///
  /// Exceptions thrown by listeners will be caught and reported using
  /// [FlutterError.reportError].
  ///
  /// Surprising behavior can result when reentrantly removing a listener (i.e.
  /// in response to a notification) that has been registered multiple times.
  /// See the discussion at [removeActionListener].
  @protected
  @visibleForTesting
  void notifyActionListeners() {
    if (_listeners.isEmpty) {
      return;
    }

    // Make a local copy so that a listener can unregister while the list is
    // being iterated over.
    final List<ActionListenerCallback> localListeners = List<ActionListenerCallback>.from(_listeners);
    for (final ActionListenerCallback listener in localListeners) {
      InformationCollector collector;
      assert(() {
        collector = () sync* {
          yield DiagnosticsProperty<Action<T>>(
            'The $runtimeType sending notification was',
            this,
            style: DiagnosticsTreeStyle.errorProperty,
          );
        };
        return true;
      }());
      try {
        if (_listeners.contains(listener)) {
          listener(this);
        }
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets library',
          context: ErrorDescription('while dispatching notifications for $runtimeType'),
          informationCollector: collector,
        ));
      }
    }
  }
}

/// A helper widget for making sure that listeners on an action are removed properly.
///
/// Listeners on the [Action] class must have their listener callbacks removed
/// with [Action.removeActionListener] when the listener is disposed of. This widget
/// helps with that, by providing a lifetime for the connection between the
/// [listener] and the [Action], and by handling the adding and removing of
/// the [listener] at the right points in the widget lifecycle.
///
/// If you listen to an [Action] widget in a widget hierarchy, you should use
/// this widget. If you are using an [Action] outside of a widget context, then
/// you must call removeListener yourself.
@immutable
class ActionListener extends StatefulWidget {
  /// Create a const [ActionListener].
  ///
  /// The [listener], [action], and [child] arguments must not be null.
  const ActionListener({
    Key key,
    @required this.listener,
    @required this.action,
    @required this.child,
  })  : assert(listener != null),
        assert(action != null),
        assert(child != null),
        super(key: key);

  /// The [ActionListenerCallback] callback to register with the [action].
  ///
  /// Must not be null.
  final ActionListenerCallback listener;

  /// The [Action] that the callback will be registered with.
  ///
  /// Must not be null.
  final Action<Intent> action;

  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  _ActionListenerState createState() => _ActionListenerState();
}

class _ActionListenerState extends State<ActionListener> {
  @override
  void initState() {
    super.initState();
    widget.action.addActionListener(widget.listener);
  }

  @override
  void didUpdateWidget(ActionListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.action == widget.action && oldWidget.listener == widget.listener) {
      return;
    }
    oldWidget.action.removeActionListener(oldWidget.listener);
    widget.action.addActionListener(widget.listener);
  }

  @override
  void dispose() {
    widget.action.removeActionListener(widget.listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// An abstract [Action] subclass that adds an optional [BuildContext] to the
/// [invoke] method to be able to provide context to actions.
///
/// [ActionDispatcher.invokeAction] checks to see if the action it is invoking
/// is a [ContextAction], and if it is, supplies it with a context.
abstract class ContextAction<T extends Intent> extends Action<T> {
  /// Called when the action is to be performed.
  ///
  /// This is called by the [ActionDispatcher] when an action is invoked via
  /// [Actions.invoke], or when an action is invoked using
  /// [ActionDispatcher.invokeAction] directly.
  ///
  /// This method is only meant to be invoked by an [ActionDispatcher], or by
  /// its subclasses, and only when [isEnabled] is true.
  ///
  /// The optional `context` parameter is the context of the invocation of the
  /// action, and in the case of an action invoked by a [ShortcutManager], via
  /// a [Shortcuts] widget, will be the context of the [Shortcuts] widget.
  ///
  /// When overriding this method, the returned value can be any Object, but
  /// changing the return type of the override to match the type of the returned
  /// value provides more type safety.
  ///
  /// For instance, if your override of `invoke` returns an `int`, then define
  /// it like so:
  ///
  /// ```dart
  /// class IncrementIntent extends Intent {
  ///   const IncrementIntent({this.index});
  ///
  ///   final int index;
  /// }
  ///
  /// class MyIncrementAction extends ContextAction<IncrementIntent> {
  ///   @override
  ///   int invoke(IncrementIntent intent, [BuildContext context]) {
  ///     return intent.index + 1;
  ///   }
  /// }
  /// ```
  @protected
  @override
  Object invoke(covariant T intent, [BuildContext context]);
}

/// The signature of a callback accepted by [CallbackAction].
typedef OnInvokeCallback<T extends Intent> = Object Function(T intent);

/// An [Action] that takes a callback in order to configure it without having to
/// create an explicit [Action] subclass just to call a callback.
///
/// See also:
///
///  * [Shortcuts], which is a widget that contains a key map, in which it looks
///    up key combinations in order to invoke actions.
///  * [Actions], which is a widget that defines a map of [Intent] to [Action]
///    and allows redefining of actions for its descendants.
///  * [ActionDispatcher], a class that takes an [Action] and invokes it using a
///    [FocusNode] for context.
class CallbackAction<T extends Intent> extends Action<T> {
  /// A constructor for a [CallbackAction].
  ///
  /// The `intentKey` and [onInvoke] parameters must not be null.
  /// The [onInvoke] parameter is required.
  CallbackAction({@required this.onInvoke}) : assert(onInvoke != null);

  /// The callback to be called when invoked.
  ///
  /// Must not be null.
  @protected
  final OnInvokeCallback<T> onInvoke;

  @override
  Object invoke(covariant T intent) => onInvoke(intent);
}

/// An action dispatcher that simply invokes the actions given to it.
///
/// See also:
///
///  - [ShortcutManager], that uses this class to invoke actions.
///  - [Shortcuts] widget, which defines key mappings to [Intent]s.
///  - [Actions] widget, which defines a mapping between a in [Intent] type and
///    an [Action].
class ActionDispatcher with Diagnosticable {
  /// Const constructor so that subclasses can be immutable.
  const ActionDispatcher();

  /// Invokes the given `action`, passing it the given `intent`.
  ///
  /// The action will be invoked with the given `context`, if given, but only if
  /// the action is a [ContextAction] subclass. If no `context` is given, and
  /// the action is a [ContextAction], then the context from the [primaryFocus]
  /// is used.
  ///
  /// Returns the object returned from [Action.invoke] if the action was
  /// successfully invoked, and null if the action is not enabled. May also
  /// return null if [Action.invoke] returns null.
  Object invokeAction(covariant Action<Intent> action, covariant Intent intent, [BuildContext context]) {
    assert(action != null);
    assert(intent != null);
    context ??= primaryFocus?.context;
    if (action.isEnabled(intent)) {
      if (action is ContextAction) {
        return action.invoke(intent, context);
      } else {
        return action.invoke(intent);
      }
    }
    return null;
  }
}

/// A widget that establishes an [ActionDispatcher] and a map of [Intent] to
/// [Action] to be used by its descendants when invoking an [Action].
///
/// Actions are typically invoked using [Actions.invoke] with the context
/// containing the ambient [Actions] widget.
///
/// See also:
///
///  * [ActionDispatcher], the object that this widget uses to manage actions.
///  * [Action], a class for containing and defining an invocation of a user
///    action.
///  * [Intent], a class that holds a unique [LocalKey] identifying an action,
///    as well as configuration information for running the [Action].
///  * [Shortcuts], a widget used to bind key combinations to [Intent]s.
class Actions extends StatefulWidget {
  /// Creates an [Actions] widget.
  ///
  /// The [child], [actions], and [dispatcher] arguments must not be null.
  const Actions({
    Key key,
    this.dispatcher,
    @required this.actions,
    @required this.child,
  })  : assert(actions != null),
        assert(child != null),
        super(key: key);

  /// The [ActionDispatcher] object that invokes actions.
  ///
  /// This is what is returned from [Actions.of], and used by [Actions.invoke].
  ///
  /// If this [dispatcher] is null, then [Actions.of] and [Actions.invoke] will
  /// look up the tree until they find an Actions widget that has a dispatcher
  /// set. If not such widget is found, then they will return/use a
  /// default-constructed [ActionDispatcher].
  final ActionDispatcher dispatcher;

  /// {@template flutter.widgets.actions.actions}
  /// A map of [Intent] keys to [Action<Intent>] objects that defines which
  /// actions this widget knows about.
  ///
  /// For performance reasons, it is recommended that a pre-built map is
  /// passed in here (e.g. a final variable from your widget class) instead of
  /// defining it inline in the build function.
  /// {@endtemplate}
  final Map<Type, Action<Intent>> actions;

  /// {@macro flutter.widgets.child}
  final Widget child;

  // Visits the Actions widget ancestors of the given element using
  // getElementForInheritedWidgetOfExactType. Returns true if the visitor found
  // what it was looking for.
  static bool _visitActionsAncestors(BuildContext context, bool visitor(InheritedElement element)) {
    InheritedElement actionsElement = context?.getElementForInheritedWidgetOfExactType<_ActionsMarker>();
    while (actionsElement != null) {
      if (visitor(actionsElement) == true) {
        break;
      }
      // _getParent is needed here because
      // context.getElementForInheritedWidgetOfExactType will return itself if it
      // happens to be of the correct type.
      final BuildContext parent = _getParent(actionsElement);
      actionsElement = parent?.getElementForInheritedWidgetOfExactType<_ActionsMarker>();
    }
    return actionsElement != null;
  }

  // Finds the nearest valid ActionDispatcher, or creates a new one if it
  // doesn't find one.
  static ActionDispatcher _findDispatcher(BuildContext context) {
    ActionDispatcher dispatcher;
    _visitActionsAncestors(context, (InheritedElement element) {
      final ActionDispatcher found = (element.widget as _ActionsMarker).dispatcher;
      if (found != null) {
        dispatcher = found;
        return true;
      }
      return false;
    });
    return dispatcher ?? const ActionDispatcher();
  }

  /// Returns a [VoidCallback] handler that invokes the bound action for the
  /// given `intent` if the action is enabled, and returns null if the action is
  /// not enabled.
  ///
  /// This is intended to be used in widgets which have something similar to an
  /// `onTap` handler, which takes a `VoidCallback`, and can be set to the
  /// result of calling this function.
  ///
  /// Creates a dependency on the [Actions] widget that maps the bound action so
  /// that if the actions change, the context will be rebuilt and find the
  /// updated action.
  static VoidCallback handler<T extends Intent>(BuildContext context, T intent, {bool nullOk = false}) {
    final Action<T> action = Actions.find<T>(context, nullOk: nullOk);
    if (action != null && action.isEnabled(intent)) {
      return () {
        Actions.of(context).invokeAction(action, intent, context);
      };
    }
    return null;
  }

  /// Finds the [Action] bound to the given intent type `T` in the given `context`.
  ///
  /// Creates a dependency on the [Actions] widget that maps the bound action so
  /// that if the actions change, the context will be rebuilt and find the
  /// updated action.
  static Action<T> find<T extends Intent>(BuildContext context, {bool nullOk = false}) {
    Action<T> action;

    _visitActionsAncestors(context, (InheritedElement element) {
      final _ActionsMarker actions = element.widget as _ActionsMarker;
      final Action<T> result = actions.actions[T] as Action<T>;
      if (result != null) {
        context.dependOnInheritedElement(element);
        action = result;
        return true;
      }
      return false;
    });

    assert(() {
      if (nullOk) {
        return true;
      }
      if (action == null) {
        throw FlutterError('Unable to find an action for a $T in an $Actions widget '
            'in the given context.\n'
            "$Actions.find() was called on a context that doesn\'t contain an "
            '$Actions widget with a mapping for the given intent type.\n'
            'The context used was:\n'
            '  $context\n'
            'The intent type requested was:\n'
            '  $T');
      }
      return true;
    }());
    return action;
  }

  /// Returns the [ActionDispatcher] associated with the [Actions] widget that
  /// most tightly encloses the given [BuildContext].
  ///
  /// Will throw if no ambient [Actions] widget is found.
  ///
  /// If `nullOk` is set to true, then if no ambient [Actions] widget is found,
  /// this will return null.
  ///
  /// The `context` argument must not be null.
  static ActionDispatcher of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    final _ActionsMarker marker = context.dependOnInheritedWidgetOfExactType<_ActionsMarker>();
    assert(() {
      if (nullOk) {
        return true;
      }
      if (marker == null) {
        throw FlutterError('Unable to find an $Actions widget in the given context.\n'
            '$Actions.of() was called with a context that does not contain an '
            '$Actions widget.\n'
            'No $Actions ancestor could be found starting from the context that '
            'was passed to $Actions.of(). This can happen if the context comes '
            'from a widget above those widgets.\n'
            'The context used was:\n'
            '  $context');
      }
      return true;
    }());
    return marker?.dispatcher ?? _findDispatcher(context);
  }

  /// Invokes the action associated with the given [Intent] using the
  /// [Actions] widget that most tightly encloses the given [BuildContext].
  ///
  /// The `context`, `intent` and `nullOk` arguments must not be null.
  ///
  /// If the given `intent` isn't found in the first [Actions.actions] map, then
  /// it will look to the next [Actions] widget in the hierarchy until it
  /// reaches the root.
  ///
  /// Will throw if no ambient [Actions] widget is found, or if the given
  /// `intent` doesn't map to an action in any of the [Actions.actions] maps
  /// that are found.
  ///
  /// Setting `nullOk` to true means that if no ambient [Actions] widget is
  /// found, then this method will return null instead of throwing.
  ///
  /// Returns the result of invoking the action's [Action.invoke] method. If
  /// no action mapping was found for the specified intent, or if the action
  /// that was found was disabled, then this returns null. Callers can detect
  /// whether or not the action is available (found, and not disabled) using
  /// [Actions.find] with its `nullOk` argument set to true.
  static Object invoke<T extends Intent>(
    BuildContext context,
    T intent, {
    bool nullOk = false,
  }) {
    assert(intent != null);
    assert(nullOk != null);
    assert(context != null);
    Action<T> action;
    InheritedElement actionElement;

    _visitActionsAncestors(context, (InheritedElement element) {
      final _ActionsMarker actions = element.widget as _ActionsMarker;
      final Action<T> result = actions.actions[intent.runtimeType] as Action<T>;
      if (result != null) {
        action = result;
        actionElement = element;
        return true;
      }
      return false;
    });

    assert(() {
      if (nullOk) {
        return true;
      }
      if (action == null) {
        throw FlutterError('Unable to find an action for an Intent with type '
            '${intent.runtimeType} in an $Actions widget in the given context.\n'
            '$Actions.invoke() was unable to find an $Actions widget that '
            "contained a mapping for the given intent, or the intent type isn't the "
            'same as the type argument to invoke (which is $T - try supplying a '
            'type argument to invoke if one was not given)\n'
            'The context used was:\n'
            '  $context\n'
            'The intent type requested was:\n'
            '  ${intent.runtimeType}');
      }
      return true;
    }());
    // Invoke the action we found using the relevant dispatcher from the Actions
    // Element we found.
    return actionElement != null ? _findDispatcher(actionElement).invokeAction(action, intent, context) : null;
  }

  @override
  State<Actions> createState() => _ActionsState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ActionDispatcher>('dispatcher', dispatcher));
    properties.add(DiagnosticsProperty<Map<Type, Action<Intent>>>('actions', actions));
  }
}

class _ActionsState extends State<Actions> {
  // The set of actions that this Actions widget is current listening to.
  Set<Action<Intent>> listenedActions = <Action<Intent>>{};
  // Used to tell the marker to rebuild its dependencies when the state of an
  // action in the map changes.
  Object rebuildKey = Object();

  @override
  void initState() {
    super.initState();
    _updateActionListeners();
  }

  void _handleActionChanged(Action<Intent> action) {
    // Generate a new key so that the marker notifies dependents.
    setState(() {
      rebuildKey = Object();
    });
  }

  void _updateActionListeners() {
    final Set<Action<Intent>> widgetActions = widget.actions.values.toSet();
    final Set<Action<Intent>> removedActions = listenedActions.difference(widgetActions);
    final Set<Action<Intent>> addedActions = widgetActions.difference(listenedActions);

    for (final Action<Intent> action in removedActions) {
      action.removeActionListener(_handleActionChanged);
    }
    for (final Action<Intent> action in addedActions) {
      action.addActionListener(_handleActionChanged);
    }
    listenedActions = widgetActions;
  }

  @override
  void didUpdateWidget(Actions oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateActionListeners();
  }

  @override
  void dispose() {
    super.dispose();
    for (final Action<Intent> action in listenedActions) {
      action.removeActionListener(_handleActionChanged);
    }
    listenedActions = null;
  }

  @override
  Widget build(BuildContext context) {
    return _ActionsMarker(
      actions: widget.actions,
      dispatcher: widget.dispatcher,
      rebuildKey: rebuildKey,
      child: widget.child,
    );
  }
}

// An inherited widget used by Actions widget for fast lookup of the Actions
// widget information.
class _ActionsMarker extends InheritedWidget {
  const _ActionsMarker({
    @required this.dispatcher,
    @required this.actions,
    @required this.rebuildKey,
    Key key,
    @required Widget child,
  })  : assert(child != null),
        assert(actions != null),
        super(key: key, child: child);

  final ActionDispatcher dispatcher;
  final Map<Type, Action<Intent>> actions;
  final Object rebuildKey;

  @override
  bool updateShouldNotify(_ActionsMarker oldWidget) {
    return rebuildKey != oldWidget.rebuildKey
        || oldWidget.dispatcher != dispatcher
        || !mapEquals<Type, Action<Intent>>(oldWidget.actions, actions);
  }
}

/// A widget that combines the functionality of [Actions], [Shortcuts],
/// [MouseRegion] and a [Focus] widget to create a detector that defines actions
/// and key bindings, and provides callbacks for handling focus and hover
/// highlights.
///
/// This widget can be used to give a control the required detection modes for
/// focus and hover handling. It is most often used when authoring a new control
/// widget, and the new control should be enabled for keyboard traversal and
/// activation.
///
/// {@tool dartpad --template=stateful_widget_material}
/// This example shows how keyboard interaction can be added to a custom control
/// that changes color when hovered and focused, and can toggle a light when
/// activated, either by touch or by hitting the `X` key on the keyboard when
/// the "And Me" button has the keyboard focus (be sure to use TAB to move the
/// focus to the "And Me" button before trying it out).
///
/// This example defines its own key binding for the `X` key, but in this case,
/// there is also a default key binding for [ActivateAction] in the default key
/// bindings created by [WidgetsApp] (the parent for [MaterialApp], and
/// [CupertinoApp]), so the `ENTER` key will also activate the buttons.
///
/// ```dart imports
/// import 'package:flutter/services.dart';
/// ```
///
/// ```dart preamble
/// class FadButton extends StatefulWidget {
///   const FadButton({Key key, this.onPressed, this.child}) : super(key: key);
///
///   final VoidCallback onPressed;
///   final Widget child;
///
///   @override
///   _FadButtonState createState() => _FadButtonState();
/// }
///
/// class _FadButtonState extends State<FadButton> {
///   bool _focused = false;
///   bool _hovering = false;
///   bool _on = false;
///   Map<Type, Action<Intent>> _actionMap;
///   Map<LogicalKeySet, Intent> _shortcutMap;
///
///   @override
///   void initState() {
///     super.initState();
///     _actionMap = <Type, Action<Intent>>{
///       ActivateIntent: CallbackAction(
///         onInvoke: (Intent intent) => _toggleState(),
///       ),
///     };
///     _shortcutMap = <LogicalKeySet, Intent>{
///       LogicalKeySet(LogicalKeyboardKey.keyX): const ActivateIntent(),
///     };
///   }
///
///   Color get color {
///     Color baseColor = Colors.lightBlue;
///     if (_focused) {
///       baseColor = Color.alphaBlend(Colors.black.withOpacity(0.25), baseColor);
///     }
///     if (_hovering) {
///       baseColor = Color.alphaBlend(Colors.black.withOpacity(0.1), baseColor);
///     }
///     return baseColor;
///   }
///
///   void _toggleState() {
///     setState(() {
///       _on = !_on;
///     });
///   }
///
///   void _handleFocusHighlight(bool value) {
///     setState(() {
///       _focused = value;
///     });
///   }
///
///   void _handleHoveHighlight(bool value) {
///     setState(() {
///       _hovering = value;
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return GestureDetector(
///       onTap: _toggleState,
///       child: FocusableActionDetector(
///         actions: _actionMap,
///         shortcuts: _shortcutMap,
///         onShowFocusHighlight: _handleFocusHighlight,
///         onShowHoverHighlight: _handleHoveHighlight,
///         child: Row(
///           children: <Widget>[
///             Container(
///               padding: EdgeInsets.all(10.0),
///               color: color,
///               child: widget.child,
///             ),
///             Container(
///               width: 30,
///               height: 30,
///               margin: EdgeInsets.all(10.0),
///               color: _on ? Colors.red : Colors.transparent,
///             ),
///           ],
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: Text('FocusableActionDetector Example'),
///     ),
///     body: Center(
///       child: Row(
///         mainAxisAlignment: MainAxisAlignment.center,
///         children: <Widget>[
///           Padding(
///             padding: const EdgeInsets.all(8.0),
///             child: TextButton(onPressed: () {}, child: Text('Press Me')),
///           ),
///           Padding(
///             padding: const EdgeInsets.all(8.0),
///             child: FadButton(onPressed: () {}, child: Text('And Me')),
///           ),
///         ],
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// This widget doesn't have any visual representation, it is just a detector that
/// provides focus and hover capabilities.
///
/// It hosts its own [FocusNode] or uses [focusNode], if given.
class FocusableActionDetector extends StatefulWidget {
  /// Create a const [FocusableActionDetector].
  ///
  /// The [enabled], [autofocus], [mouseCursor], and [child] arguments must not be null.
  const FocusableActionDetector({
    Key key,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.shortcuts,
    this.actions,
    this.onShowFocusHighlight,
    this.onShowHoverHighlight,
    this.onFocusChange,
    this.mouseCursor = MouseCursor.defer,
    @required this.child,
  })  : assert(enabled != null),
        assert(autofocus != null),
        assert(mouseCursor != null),
        assert(child != null),
        super(key: key);

  /// Is this widget enabled or not.
  ///
  /// If disabled, will not send any notifications needed to update highlight or
  /// focus state, and will not define or respond to any actions or shortcuts.
  ///
  /// When disabled, adds [Focus] to the widget tree, but sets
  /// [Focus.canRequestFocus] to false.
  final bool enabled;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.actions.actions}
  final Map<Type, Action<Intent>> actions;

  /// {@macro flutter.widgets.shortcuts.shortcuts}
  final Map<LogicalKeySet, Intent> shortcuts;

  /// A function that will be called when the focus highlight should be shown or
  /// hidden.
  ///
  /// This method is not triggered at the unmount of the widget.
  final ValueChanged<bool> onShowFocusHighlight;

  /// A function that will be called when the hover highlight should be shown or hidden.
  ///
  /// This method is not triggered at the unmount of the widget.
  final ValueChanged<bool> onShowHoverHighlight;

  /// A function that will be called when the focus changes.
  ///
  /// Called with true if the [focusNode] has primary focus.
  final ValueChanged<bool> onFocusChange;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// The [mouseCursor] defaults to [MouseCursor.defer], deferring the choice of
  /// cursor to the next region behind it in hit-test order.
  final MouseCursor mouseCursor;

  /// The child widget for this [FocusableActionDetector] widget.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  _FocusableActionDetectorState createState() => _FocusableActionDetectorState();
}

class _FocusableActionDetectorState extends State<FocusableActionDetector> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
      _updateHighlightMode(FocusManager.instance.highlightMode);
    });
    FocusManager.instance.addHighlightModeListener(_handleFocusHighlightModeChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_handleFocusHighlightModeChange);
    super.dispose();
  }

  bool _canShowHighlight = false;
  void _updateHighlightMode(FocusHighlightMode mode) {
    _mayTriggerCallback(task: () {
      switch (FocusManager.instance.highlightMode) {
        case FocusHighlightMode.touch:
          _canShowHighlight = false;
          break;
        case FocusHighlightMode.traditional:
          _canShowHighlight = true;
          break;
      }
    });
  }

  // Have to have this separate from the _updateHighlightMode because it gets
  // called in initState, where things aren't mounted yet.
  // Since this method is a highlight mode listener, it is only called
  // immediately following pointer events.
  void _handleFocusHighlightModeChange(FocusHighlightMode mode) {
    if (!mounted) {
      return;
    }
    _updateHighlightMode(mode);
  }

  bool _hovering = false;
  void _handleMouseEnter(PointerEnterEvent event) {
    if (!_hovering) {
      _mayTriggerCallback(task: () {
        _hovering = true;
      });
    }
  }

  void _handleMouseExit(PointerExitEvent event) {
    if (_hovering) {
      _mayTriggerCallback(task: () {
        _hovering = false;
      });
    }
  }

  bool _focused = false;
  void _handleFocusChange(bool focused) {
    if (_focused != focused) {
      _mayTriggerCallback(task: () {
        _focused = focused;
      });
      widget.onFocusChange?.call(_focused);
    }
  }

  // Record old states, do `task` if not null, then compare old states with the
  // new states, and trigger callbacks if necessary.
  //
  // The old states are collected from `oldWidget` if it is provided, or the
  // current widget (before doing `task`) otherwise. The new states are always
  // collected from the current widget.
  void _mayTriggerCallback({VoidCallback task, FocusableActionDetector oldWidget}) {
    bool shouldShowHoverHighlight(FocusableActionDetector target) {
      return _hovering && target.enabled && _canShowHighlight;
    }

    bool canRequestFocus(FocusableActionDetector target) {
      final NavigationMode mode = MediaQuery.of(context, nullOk: true)?.navigationMode ?? NavigationMode.traditional;
      switch (mode) {
        case NavigationMode.traditional:
          return target.enabled;
        case NavigationMode.directional:
          return true;
      }
      assert(false, 'Navigation mode $mode not handled');
      return null;
    }

    bool shouldShowFocusHighlight(FocusableActionDetector target) {
      return _focused && _canShowHighlight && canRequestFocus(target);
    }

    assert(SchedulerBinding.instance.schedulerPhase != SchedulerPhase.persistentCallbacks);
    final FocusableActionDetector oldTarget = oldWidget ?? widget;
    final bool didShowHoverHighlight = shouldShowHoverHighlight(oldTarget);
    final bool didShowFocusHighlight = shouldShowFocusHighlight(oldTarget);
    if (task != null) {
      task();
    }
    final bool doShowHoverHighlight = shouldShowHoverHighlight(widget);
    final bool doShowFocusHighlight = shouldShowFocusHighlight(widget);
    if (didShowFocusHighlight != doShowFocusHighlight) {
      widget.onShowFocusHighlight?.call(doShowFocusHighlight);
    }
    if (didShowHoverHighlight != doShowHoverHighlight) {
      widget.onShowHoverHighlight?.call(doShowHoverHighlight);
    }
  }

  @override
  void didUpdateWidget(FocusableActionDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        _mayTriggerCallback(oldWidget: oldWidget);
      });
    }
  }

  bool get _canRequestFocus {
    final NavigationMode mode = MediaQuery.of(context, nullOk: true)?.navigationMode ?? NavigationMode.traditional;
    switch (mode) {
      case NavigationMode.traditional:
        return widget.enabled;
      case NavigationMode.directional:
        return true;
    }
    assert(false, 'NavigationMode $mode not handled.');
    return null;
  }

  // This global key is needed to keep only the necessary widgets in the tree
  // while maintaining the subtree's state.
  //
  // See https://github.com/flutter/flutter/issues/64058 for an explanation of
  // why using a global key over keeping the shape of the tree.
  final GlobalKey _mouseRegionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget child = MouseRegion(
      key: _mouseRegionKey,
      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,
      cursor: widget.mouseCursor,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        canRequestFocus: _canRequestFocus,
        onFocusChange: _handleFocusChange,
        child: widget.child,
      ),
    );
    if (widget.enabled && widget.actions != null && widget.actions.isNotEmpty) {
      child = Actions(actions: widget.actions, child: child);
    }
    if (widget.enabled && widget.shortcuts != null && widget.shortcuts.isNotEmpty) {
      child = Shortcuts(shortcuts: widget.shortcuts, child: child);
    }
    return child;
  }
}

/// An [Intent], that, as the name implies, is bound to a [DoNothingAction].
///
/// Attaching a [DoNothingIntent] to a [Shortcuts] mapping is one way to disable
/// a keyboard shortcut defined by a widget higher in the widget hierarchy.
///
/// This intent cannot be subclassed.
class DoNothingIntent extends Intent {
  /// Creates a const [DoNothingIntent].
  factory DoNothingIntent() => const DoNothingIntent._();

  // Make DoNothingIntent constructor private so it can't be subclassed.
  const DoNothingIntent._();
}

/// An [Action], that, as the name implies, does nothing.
///
/// Attaching a [DoNothingAction] to an [Actions] mapping is one way to disable
/// an action defined by a widget higher in the widget hierarchy.
///
/// This action can be bound to any intent.
///
/// See also:
///  - [DoNothingIntent], which is an intent that can be bound to a keystroke in
///    a [Shortcuts] widget to do nothing.
class DoNothingAction extends Action<Intent> {
  @override
  void invoke(Intent intent) {}
}

/// An intent that activates the currently focused control.
class ActivateIntent extends Intent {
  /// Creates a const [ActivateIntent] so subclasses can be const.
  const ActivateIntent();
}

/// An action that activates the currently focused control.
///
/// This is an abstract class that serves as a base class for actions that
/// activate a control. By default, is bound to [LogicalKeyboardKey.enter],
/// [LogicalKeyboardKey.gameButtonA], and [LogicalKeyboardKey.space] in the
/// default keyboard map in [WidgetsApp].
abstract class ActivateAction extends Action<ActivateIntent> {}

/// An intent that selects the currently focused control.
class SelectIntent extends Intent {}

/// An action that selects the currently focused control.
///
/// This is an abstract class that serves as a base class for actions that
/// select something. It is not bound to any key by default.
abstract class SelectAction extends Action<SelectIntent> {}

/// An [Intent] that dismisses the currently focused widget.
///
/// The [WidgetsApp.defaultShortcuts] binds this intent to the
/// [LogicalKeyboardKey.escape] and [LogicalKeyboardKey.gameButtonB] keys.
///
/// See also:
///  - [ModalRoute] which listens for this intent to dismiss modal routes
///    (dialogs, pop-up menus, drawers, etc).
class DismissIntent extends Intent {
  /// Creates a const [DismissIntent].
  const DismissIntent();
}

/// An action that dismisses the focused widget.
///
/// This is an abstract class that serves as a base class for dismiss actions.
abstract class DismissAction extends Action<DismissIntent> {}
