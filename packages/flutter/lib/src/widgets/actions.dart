// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

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
  late final BuildContext parent;
  context.visitAncestorElements((Element ancestor) {
    parent = ancestor;
    return false;
  });
  return parent;
}

/// An abstract class representing a particular configuration of an [Action].
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
abstract class Intent with Diagnosticable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Intent();

  /// An intent that is mapped to a [DoNothingAction], which, as the name
  /// implies, does nothing.
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
/// ### Action Overriding
///
/// When using a leaf widget to build a more specialized widget, it's sometimes
/// desirable to change the default handling of an [Intent] defined in the leaf
/// widget. For instance, [TextField]'s [SelectAllTextIntent] by default selects
/// the text it currently contains, but in a US phone number widget that
/// consists of 3 different [TextField]s (area code, prefix and line number),
/// [SelectAllTextIntent] should instead select the text within all 3
/// [TextField]s.
///
/// An overridable [Action] is a special kind of [Action] created using the
/// [Action.overridable] constructor. It has access to a default [Action], and a
/// nullable override [Action]. It has the same behavior as its override if that
/// exists, and mirrors the behavior of its `defaultAction` otherwise.
///
/// The [Action.overridable] constructor creates overridable [Action]s that use
/// a [BuildContext] to find a suitable override in its ancestor [Actions]
/// widget. This can be used to provide a default implementation when creating a
/// general purpose leaf widget, and later override it when building a more
/// specialized widget using that leaf widget. Using the [TextField] example
/// above, the [TextField] widget uses an overridable [Action] to provide a
/// sensible default for [SelectAllTextIntent], while still allowing app
/// developers to change that if they add an ancestor [Actions] widget that maps
/// [SelectAllTextIntent] to a different [Action].
///
/// See also:
///
///  * [Shortcuts], which is a widget that contains a key map, in which it looks
///    up key combinations in order to invoke actions.
///  * [Actions], which is a widget that defines a map of [Intent] to [Action]
///    and allows redefining of actions for its descendants.
///  * [ActionDispatcher], a class that takes an [Action] and invokes it, passing
///    a given [Intent].
///  * [Action.overridable] for an example on how to make an [Action]
///    overridable.
abstract class Action<T extends Intent> with Diagnosticable {
  /// Creates an [Action].
  Action();

  /// Creates an [Action] that allows itself to be overridden by the closest
  /// ancestor [Action] in the given [context] that handles the same [Intent],
  /// if one exists.
  ///
  /// When invoked, the resulting [Action] tries to find the closest [Action] in
  /// the given `context` that handles the same type of [Intent] as the
  /// `defaultAction`, then calls its [Action.invoke] method. When no override
  /// [Action]s can be found, it invokes the `defaultAction`.
  ///
  /// An overridable action delegates everything to its override if one exists,
  /// and has the same behavior as its `defaultAction` otherwise. For this
  /// reason, the override has full control over whether and how an [Intent]
  /// should be handled, or a key event should be consumed. An override
  /// [Action]'s [callingAction] property will be set to the [Action] it
  /// currently overrides, giving it access to the default behavior. See the
  /// [callingAction] property for an example.
  ///
  /// The `context` argument is the [BuildContext] to find the override with. It
  /// is typically a [BuildContext] above the [Actions] widget that contains
  /// this overridable [Action].
  ///
  /// The `defaultAction` argument is the [Action] to be invoked where there's
  /// no ancestor [Action]s can't be found in `context` that handle the same
  /// type of [Intent].
  ///
  /// This is useful for providing a set of default [Action]s in a leaf widget
  /// to allow further overriding, or to allow the [Intent] to propagate to
  /// parent widgets that also support this [Intent].
  ///
  /// {@tool dartpad}
  /// This sample implements a custom text input field that handles the
  /// [DeleteCharacterIntent] intent, as well as a US telephone number input
  /// widget that consists of multiple text fields for area code, prefix and line
  /// number. When the backspace key is pressed, the phone number input widget
  /// sends the focus to the preceding text field when the currently focused
  /// field becomes empty.
  ///
  /// ** See code in examples/api/lib/widgets/actions/action.action_overridable.0.dart **
  /// {@end-tool}
  factory Action.overridable({
    required Action<T> defaultAction,
    required BuildContext context,
  }) {
    return defaultAction._makeOverridableAction(context);
  }

  final ObserverList<ActionListenerCallback> _listeners = ObserverList<ActionListenerCallback>();

  Action<T>? _currentCallingAction;
  // ignore: use_setters_to_change_properties, (code predates enabling of this lint)
  void _updateCallingAction(Action<T>? value) {
    _currentCallingAction = value;
  }

  /// The [Action] overridden by this [Action].
  ///
  /// The [Action.overridable] constructor creates an overridable [Action] that
  /// allows itself to be overridden by the closest ancestor [Action], and falls
  /// back to its own `defaultAction` when no overrides can be found. When an
  /// override is present, an overridable [Action] forwards all incoming
  /// method calls to the override, and allows the override to access the
  /// `defaultAction` via its [callingAction] property.
  ///
  /// Before forwarding the call to the override, the overridable [Action] is
  /// responsible for setting [callingAction] to its `defaultAction`, which is
  /// already taken care of by the overridable [Action] created using
  /// [Action.overridable].
  ///
  /// This property is only non-null when this [Action] is an override of the
  /// [callingAction], and is currently being invoked from [callingAction].
  ///
  /// Invoking [callingAction]'s methods, or accessing its properties, is
  /// allowed and does not introduce infinite loops or infinite recursions.
  ///
  /// {@tool snippet}
  /// An example `Action` that handles [PasteTextIntent] but has mostly the same
  /// behavior as the overridable action. It's OK to call
  /// `callingAction?.isActionEnabled` in the implementation of this `Action`.
  ///
  /// ```dart
  /// class MyPasteAction extends Action<PasteTextIntent> {
  ///   @override
  ///   Object? invoke(PasteTextIntent intent) {
  ///     print(intent);
  ///     return callingAction?.invoke(intent);
  ///   }
  ///
  ///   @override
  ///   bool get isActionEnabled => callingAction?.isActionEnabled ?? false;
  ///
  ///   @override
  ///   bool consumesKey(PasteTextIntent intent) => callingAction?.consumesKey(intent) ?? false;
  /// }
  /// ```
  /// {@end-tool}
  @protected
  Action<T>? get callingAction => _currentCallingAction;

  /// Gets the type of intent this action responds to.
  Type get intentType => T;

  /// Returns true if the action is enabled and is ready to be invoked.
  ///
  /// This will be called by the [ActionDispatcher] before attempting to invoke
  /// the action.
  bool isEnabled(T intent) => isActionEnabled;

  /// Whether this [Action] is inherently enabled.
  ///
  /// If [isActionEnabled] is false, then this [Action] is disabled for any
  /// given [Intent].
  //
  /// If the enabled state changes, overriding subclasses must call
  /// [notifyActionListeners] to notify any listeners of the change.
  ///
  /// In the case of an overridable `Action`, accessing this property creates
  /// an dependency on the overridable `Action`s `lookupContext`.
  bool get isActionEnabled => true;

  /// Indicates whether this action should treat key events mapped to this
  /// action as being "handled" when it is invoked via the key event.
  ///
  /// If the key is handled, then no other key event handlers in the focus chain
  /// will receive the event.
  ///
  /// If the key event is not handled, it will be passed back to the engine, and
  /// continue to be processed there, allowing text fields and non-Flutter
  /// widgets to receive the key event.
  ///
  /// The default implementation returns true.
  bool consumesKey(T intent) => true;

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
  ///
  /// To receive the result of invoking an action, it must be invoked using
  /// [Actions.invoke], or by invoking it using an [ActionDispatcher]. An action
  /// invoked via a [Shortcuts] widget will have its return value ignored.
  @protected
  Object? invoke(T intent);

  /// Register a callback to listen for changes to the state of this action.
  ///
  /// If you call this, you must call [removeActionListener] a matching number
  /// of times, or memory leaks will occur. To help manage this and avoid memory
  /// leaks, use of the [ActionListener] widget to register and unregister your
  /// listener appropriately is highly recommended.
  ///
  /// {@template flutter.widgets.Action.addActionListener}
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
  /// {@macro flutter.widgets.Action.addActionListener}
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
  @pragma('vm:notify-debugger-on-exception')
  void notifyActionListeners() {
    if (_listeners.isEmpty) {
      return;
    }

    // Make a local copy so that a listener can unregister while the list is
    // being iterated over.
    final List<ActionListenerCallback> localListeners = List<ActionListenerCallback>.of(_listeners);
    for (final ActionListenerCallback listener in localListeners) {
      InformationCollector? collector;
      assert(() {
        collector = () => <DiagnosticsNode>[
          DiagnosticsProperty<Action<T>>(
            'The $runtimeType sending notification was',
            this,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ];
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

  Action<T> _makeOverridableAction(BuildContext context) {
    return _OverridableAction<T>(defaultAction: this, lookupContext: context);
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
///
/// {@tool dartpad}
/// This example shows how ActionListener handles adding and removing of
/// the [listener] in the widget lifecycle.
///
/// ** See code in examples/api/lib/widgets/actions/action_listener.0.dart **
/// {@end-tool}
///
@immutable
class ActionListener extends StatefulWidget {
  /// Create a const [ActionListener].
  ///
  /// The [listener], [action], and [child] arguments must not be null.
  const ActionListener({
    Key? key,
    required this.listener,
    required this.action,
    required this.child,
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

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<ActionListener> createState() => _ActionListenerState();
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
  Object? invoke(T intent, [BuildContext? context]);

  @override
  ContextAction<T> _makeOverridableAction(BuildContext context) {
    return _OverridableContextAction<T>(defaultAction: this, lookupContext: context);
  }
}

/// The signature of a callback accepted by [CallbackAction].
typedef OnInvokeCallback<T extends Intent> = Object? Function(T intent);

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
  CallbackAction({required this.onInvoke}) : assert(onInvoke != null);

  /// The callback to be called when invoked.
  ///
  /// Must not be null.
  @protected
  final OnInvokeCallback<T> onInvoke;

  @override
  Object? invoke(T intent) => onInvoke(intent);
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
  /// Creates an action dispatcher that invokes actions directly.
  const ActionDispatcher();

  /// Invokes the given `action`, passing it the given `intent`.
  ///
  /// The action will be invoked with the given `context`, if given, but only if
  /// the action is a [ContextAction] subclass. If no `context` is given, and
  /// the action is a [ContextAction], then the context from the [primaryFocus]
  /// is used.
  ///
  /// Returns the object returned from [Action.invoke].
  ///
  /// The caller must receive a `true` result from [Action.isEnabled] before
  /// calling this function. This function will assert if the action is not
  /// enabled when called.
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    assert(action != null);
    assert(intent != null);
    assert(action.isEnabled(intent), 'Action must be enabled when calling invokeAction');
    if (action is ContextAction) {
      context ??= primaryFocus?.context;
      return action.invoke(intent, context);
    } else {
      return action.invoke(intent);
    }
  }
}

/// A widget that establishes an [ActionDispatcher] and a map of [Intent] to
/// [Action] to be used by its descendants when invoking an [Action].
///
/// Actions are typically invoked using [Actions.invoke] with the context
/// containing the ambient [Actions] widget.
///
/// {@tool dartpad}
/// This example creates a custom [Action] subclass `ModifyAction` for modifying
/// a model, and another, `SaveAction` for saving it.
///
/// This example demonstrates passing arguments to the [Intent] to be carried to
/// the [Action]. Actions can get data either from their own construction (like
/// the `model` in this example), or from the intent passed to them when invoked
/// (like the increment `amount` in this example).
///
/// This example also demonstrates how to use Intents to limit a widget's
/// dependencies on its surroundings. The `SaveButton` widget defined in this
/// example can invoke actions defined in its ancestor widgets, which can be
/// customized to match the part of the widget tree that it is in. It doesn't
/// need to know about the `SaveAction` class, only the `SaveIntent`, and it
/// only needs to know about a value notifier, not the entire model.
///
/// ** See code in examples/api/lib/widgets/actions/actions.0.dart **
/// {@end-tool}
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
    Key? key,
    this.dispatcher,
    required this.actions,
    required this.child,
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
  final ActionDispatcher? dispatcher;

  /// {@template flutter.widgets.actions.actions}
  /// A map of [Intent] keys to [Action<Intent>] objects that defines which
  /// actions this widget knows about.
  ///
  /// For performance reasons, it is recommended that a pre-built map is
  /// passed in here (e.g. a final variable from your widget class) instead of
  /// defining it inline in the build function.
  /// {@endtemplate}
  final Map<Type, Action<Intent>> actions;

  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  // Visits the Actions widget ancestors of the given element using
  // getElementForInheritedWidgetOfExactType. Returns true if the visitor found
  // what it was looking for.
  static bool _visitActionsAncestors(BuildContext context, bool Function(InheritedElement element) visitor) {
    InheritedElement? actionsElement = context.getElementForInheritedWidgetOfExactType<_ActionsMarker>();
    while (actionsElement != null) {
      if (visitor(actionsElement) == true) {
        break;
      }
      // _getParent is needed here because
      // context.getElementForInheritedWidgetOfExactType will return itself if it
      // happens to be of the correct type.
      final BuildContext parent = _getParent(actionsElement);
      actionsElement = parent.getElementForInheritedWidgetOfExactType<_ActionsMarker>();
    }
    return actionsElement != null;
  }

  // Finds the nearest valid ActionDispatcher, or creates a new one if it
  // doesn't find one.
  static ActionDispatcher _findDispatcher(BuildContext context) {
    ActionDispatcher? dispatcher;
    _visitActionsAncestors(context, (InheritedElement element) {
      final ActionDispatcher? found = (element.widget as _ActionsMarker).dispatcher;
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
  /// not enabled, or no matching action is found.
  ///
  /// This is intended to be used in widgets which have something similar to an
  /// `onTap` handler, which takes a `VoidCallback`, and can be set to the
  /// result of calling this function.
  ///
  /// Creates a dependency on the [Actions] widget that maps the bound action so
  /// that if the actions change, the context will be rebuilt and find the
  /// updated action.
  static VoidCallback? handler<T extends Intent>(BuildContext context, T intent) {
    final Action<T>? action = Actions.maybeFind<T>(context);
    if (action != null && action.isEnabled(intent)) {
      return () {
        // Could be that the action was enabled when the closure was created,
        // but is now no longer enabled, so check again.
        if (action.isEnabled(intent)) {
          Actions.of(context).invokeAction(action, intent, context);
        }
      };
    }
    return null;
  }

  /// Finds the [Action] bound to the given intent type `T` in the given `context`.
  ///
  /// Creates a dependency on the [Actions] widget that maps the bound action so
  /// that if the actions change, the context will be rebuilt and find the
  /// updated action.
  ///
  /// The optional `intent` argument supplies the type of the intent to look for
  /// if the concrete type of the intent sought isn't available. If not
  /// supplied, then `T` is used.
  ///
  /// If no [Actions] widget surrounds the given context, this function will
  /// assert in debug mode, and throw an exception in release mode.
  ///
  /// See also:
  ///
  ///  * [maybeFind], which is similar to this function, but will return null if
  ///    no [Actions] ancestor is found.
  static Action<T> find<T extends Intent>(BuildContext context, { T? intent }) {
    final Action<T>? action = maybeFind(context, intent: intent);

    assert(() {
      if (action == null) {
        final Type type = intent?.runtimeType ?? T;
        throw FlutterError(
          'Unable to find an action for a $type in an $Actions widget '
          'in the given context.\n'
          "$Actions.find() was called on a context that doesn't contain an "
          '$Actions widget with a mapping for the given intent type.\n'
          'The context used was:\n'
          '  $context\n'
          'The intent type requested was:\n'
          '  $type',
        );
      }
      return true;
    }());
    return action!;
  }

  /// Finds the [Action] bound to the given intent type `T` in the given `context`.
  ///
  /// Creates a dependency on the [Actions] widget that maps the bound action so
  /// that if the actions change, the context will be rebuilt and find the
  /// updated action.
  ///
  /// The optional `intent` argument supplies the type of the intent to look for
  /// if the concrete type of the intent sought isn't available. If not
  /// supplied, then `T` is used.
  ///
  /// If no [Actions] widget surrounds the given context, this function will
  /// return null.
  ///
  /// See also:
  ///
  ///  * [find], which is similar to this function, but will throw if
  ///    no [Actions] ancestor is found.
  static Action<T>? maybeFind<T extends Intent>(BuildContext context, { T? intent }) {
    Action<T>? action;

    // Specialize the type if a runtime example instance of the intent is given.
    // This allows this function to be called by code that doesn't know the
    // concrete type of the intent at compile time.
    final Type type = intent?.runtimeType ?? T;
    assert(
      type != Intent,
      'The type passed to "find" resolved to "Intent": either a non-Intent '
      'generic type argument or an example intent derived from Intent must be '
      'specified. Intent may be used as the generic type as long as the optional '
      '"intent" argument is passed.',
    );

    _visitActionsAncestors(context, (InheritedElement element) {
      final _ActionsMarker actions = element.widget as _ActionsMarker;
      final Action<T>? result = _castAction(actions, intent: intent);
      if (result != null) {
        context.dependOnInheritedElement(element);
        action = result;
        return true;
      }
      return false;
    });

    return action;
  }

  static Action<T>? _maybeFindWithoutDependingOn<T extends Intent>(BuildContext context, { T? intent }) {
    Action<T>? action;

    // Specialize the type if a runtime example instance of the intent is given.
    // This allows this function to be called by code that doesn't know the
    // concrete type of the intent at compile time.
    final Type type = intent?.runtimeType ?? T;
    assert(
      type != Intent,
      'The type passed to "find" resolved to "Intent": either a non-Intent '
      'generic type argument or an example intent derived from Intent must be '
      'specified. Intent may be used as the generic type as long as the optional '
      '"intent" argument is passed.',
    );

    _visitActionsAncestors(context, (InheritedElement element) {
      final _ActionsMarker actions = element.widget as _ActionsMarker;
      final Action<T>? result = _castAction(actions, intent: intent);
      if (result != null) {
        action = result;
        return true;
      }
      return false;
    });

    return action;
  }

  // Find the [Action] that handles the given `intent` in the given
  // `_ActionsMarker`, and verify it has the right type parameter.
  static Action<T>? _castAction<T extends Intent>(_ActionsMarker actionsMarker, { T? intent }) {
    final Action<Intent>? mappedAction = actionsMarker.actions[intent?.runtimeType ?? T];
    if (mappedAction is Action<T>?) {
      return mappedAction;
    } else {
      assert(
        false,
        '$T cannot be handled by an Action of runtime type ${mappedAction.runtimeType}.'
      );
      return null;
    }
  }

  /// Returns the [ActionDispatcher] associated with the [Actions] widget that
  /// most tightly encloses the given [BuildContext].
  ///
  /// Will return a newly created [ActionDispatcher] if no ambient [Actions]
  /// widget is found.
  static ActionDispatcher of(BuildContext context) {
    assert(context != null);
    final _ActionsMarker? marker = context.dependOnInheritedWidgetOfExactType<_ActionsMarker>();
    return marker?.dispatcher ?? _findDispatcher(context);
  }

  /// Invokes the action associated with the given [Intent] using the
  /// [Actions] widget that most tightly encloses the given [BuildContext].
  ///
  /// This method returns the result of invoking the action's [Action.invoke]
  /// method.
  ///
  /// The `context` and `intent` arguments must not be null.
  ///
  /// If the given `intent` doesn't map to an action, then it will look to the
  /// next ancestor [Actions] widget in the hierarchy until it reaches the root.
  ///
  /// This method will throw an exception if no ambient [Actions] widget is
  /// found, or when a suitable [Action] is found but it returns false for
  /// [Action.isEnabled].
  static Object? invoke<T extends Intent>(
    BuildContext context,
    T intent,
  ) {
    assert(intent != null);
    assert(context != null);
    Object? returnValue;

    final bool actionFound = _visitActionsAncestors(context, (InheritedElement element) {
      final _ActionsMarker actions = element.widget as _ActionsMarker;
      final Action<T>? result = _castAction(actions, intent: intent);
      if (result != null && result.isEnabled(intent)) {
        // Invoke the action we found using the relevant dispatcher from the Actions
        // Element we found.
        returnValue = _findDispatcher(element).invokeAction(result, intent, context);
      }
      return result != null;
    });

    assert(() {
      if (!actionFound) {
        throw FlutterError(
          'Unable to find an action for an Intent with type '
          '${intent.runtimeType} in an $Actions widget in the given context.\n'
          '$Actions.invoke() was unable to find an $Actions widget that '
          "contained a mapping for the given intent, or the intent type isn't the "
          'same as the type argument to invoke (which is $T - try supplying a '
          'type argument to invoke if one was not given)\n'
          'The context used was:\n'
          '  $context\n'
          'The intent type requested was:\n'
          '  ${intent.runtimeType}',
        );
      }
      return true;
    }());
    return returnValue;
  }

  /// Invokes the action associated with the given [Intent] using the
  /// [Actions] widget that most tightly encloses the given [BuildContext].
  ///
  /// This method returns the result of invoking the action's [Action.invoke]
  /// method. If no action mapping was found for the specified intent, or if the
  /// first action found was disabled, or the action itself returns null
  /// from [Action.invoke], then this method returns null.
  ///
  /// The `context` and `intent` arguments must not be null.
  ///
  /// If the given `intent` doesn't map to an action, then it will look to the
  /// next ancestor [Actions] widget in the hierarchy until it reaches the root.
  /// If a suitable [Action] is found but its [Action.isEnabled] returns false,
  /// the search will stop and this method will return null.
  static Object? maybeInvoke<T extends Intent>(
    BuildContext context,
    T intent,
  ) {
    assert(intent != null);
    assert(context != null);
    Object? returnValue;

    _visitActionsAncestors(context, (InheritedElement element) {
      final _ActionsMarker actions = element.widget as _ActionsMarker;
      final Action<T>? result = _castAction(actions, intent: intent);
      if (result != null && result.isEnabled(intent)) {
        // Invoke the action we found using the relevant dispatcher from the Actions
        // Element we found.
        returnValue = _findDispatcher(element).invokeAction(result, intent, context);
      }
      return result != null;
    });
    return returnValue;
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
  Set<Action<Intent>>? listenedActions = <Action<Intent>>{};
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
    final Set<Action<Intent>> removedActions = listenedActions!.difference(widgetActions);
    final Set<Action<Intent>> addedActions = widgetActions.difference(listenedActions!);

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
    for (final Action<Intent> action in listenedActions!) {
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
    required this.dispatcher,
    required this.actions,
    required this.rebuildKey,
    Key? key,
    required Widget child,
  })  : assert(child != null),
        assert(actions != null),
        super(key: key, child: child);

  final ActionDispatcher? dispatcher;
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
/// {@tool dartpad}
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
/// ** See code in examples/api/lib/widgets/actions/focusable_action_detector.0.dart **
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
    Key? key,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.descendantsAreFocusable = true,
    this.descendantsAreTraversable = true,
    this.shortcuts,
    this.actions,
    this.onShowFocusHighlight,
    this.onShowHoverHighlight,
    this.onFocusChange,
    this.mouseCursor = MouseCursor.defer,
    required this.child,
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
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.Focus.descendantsAreFocusable}
  final bool descendantsAreFocusable;

  /// {@macro flutter.widgets.Focus.descendantsAreTraversable}
  final bool descendantsAreTraversable;

  /// {@macro flutter.widgets.actions.actions}
  final Map<Type, Action<Intent>>? actions;

  /// {@macro flutter.widgets.shortcuts.shortcuts}
  final Map<ShortcutActivator, Intent>? shortcuts;

  /// A function that will be called when the focus highlight should be shown or
  /// hidden.
  ///
  /// This method is not triggered at the unmount of the widget.
  final ValueChanged<bool>? onShowFocusHighlight;

  /// A function that will be called when the hover highlight should be shown or hidden.
  ///
  /// This method is not triggered at the unmount of the widget.
  final ValueChanged<bool>? onShowHoverHighlight;

  /// A function that will be called when the focus changes.
  ///
  /// Called with true if the [focusNode] has primary focus.
  final ValueChanged<bool>? onFocusChange;

  /// The cursor for a mouse pointer when it enters or is hovering over the
  /// widget.
  ///
  /// The [mouseCursor] defaults to [MouseCursor.defer], deferring the choice of
  /// cursor to the next region behind it in hit-test order.
  final MouseCursor mouseCursor;

  /// The child widget for this [FocusableActionDetector] widget.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<FocusableActionDetector> createState() => _FocusableActionDetectorState();
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
  void _mayTriggerCallback({VoidCallback? task, FocusableActionDetector? oldWidget}) {
    bool shouldShowHoverHighlight(FocusableActionDetector target) {
      return _hovering && target.enabled && _canShowHighlight;
    }

    bool canRequestFocus(FocusableActionDetector target) {
      final NavigationMode mode = MediaQuery.maybeOf(context)?.navigationMode ?? NavigationMode.traditional;
      switch (mode) {
        case NavigationMode.traditional:
          return target.enabled;
        case NavigationMode.directional:
          return true;
      }
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
    final NavigationMode mode = MediaQuery.maybeOf(context)?.navigationMode ?? NavigationMode.traditional;
    switch (mode) {
      case NavigationMode.traditional:
        return widget.enabled;
      case NavigationMode.directional:
        return true;
    }
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
        descendantsAreFocusable: widget.descendantsAreFocusable,
        descendantsAreTraversable: widget.descendantsAreTraversable,
        canRequestFocus: _canRequestFocus,
        onFocusChange: _handleFocusChange,
        child: widget.child,
      ),
    );
    if (widget.enabled && widget.actions != null && widget.actions!.isNotEmpty) {
      child = Actions(actions: widget.actions!, child: child);
    }
    if (widget.enabled && widget.shortcuts != null && widget.shortcuts!.isNotEmpty) {
      child = Shortcuts(shortcuts: widget.shortcuts!, child: child);
    }
    return child;
  }
}

/// An [Intent], that is bound to a [DoNothingAction].
///
/// Attaching a [DoNothingIntent] to a [Shortcuts] mapping is one way to disable
/// a keyboard shortcut defined by a widget higher in the widget hierarchy and
/// consume any key event that triggers it via a shortcut.
///
/// This intent cannot be subclassed.
///
/// See also:
///
///  * [DoNothingAndStopPropagationIntent], a similar intent that will not
///    handle the key event, but will still keep it from being passed to other key
///    handlers in the focus chain.
class DoNothingIntent extends Intent {
  /// Creates a const [DoNothingIntent].
  factory DoNothingIntent() => const DoNothingIntent._();

  // Make DoNothingIntent constructor private so it can't be subclassed.
  const DoNothingIntent._();
}

/// An [Intent], that is bound to a [DoNothingAction], but, in addition to not
/// performing an action, also stops the propagation of the key event bound to
/// this intent to other key event handlers in the focus chain.
///
/// Attaching a [DoNothingAndStopPropagationIntent] to a [Shortcuts.shortcuts]
/// mapping is one way to disable a keyboard shortcut defined by a widget higher
/// in the widget hierarchy. In addition, the bound [DoNothingAction] will
/// return false from [DoNothingAction.consumesKey], causing the key bound to
/// this intent to be passed on to the platform embedding as "not handled" with
/// out passing it to other key handlers in the focus chain (e.g. parent
/// `Shortcuts` widgets higher up in the chain).
///
/// This intent cannot be subclassed.
///
/// See also:
///
///  * [DoNothingIntent], a similar intent that will handle the key event.
class DoNothingAndStopPropagationIntent extends Intent {
  /// Creates a const [DoNothingAndStopPropagationIntent].
  factory DoNothingAndStopPropagationIntent() => const DoNothingAndStopPropagationIntent._();

  // Make DoNothingAndStopPropagationIntent constructor private so it can't be subclassed.
  const DoNothingAndStopPropagationIntent._();
}

/// An [Action], that doesn't perform any action when invoked.
///
/// Attaching a [DoNothingAction] to an [Actions.actions] mapping is a way to
/// disable an action defined by a widget higher in the widget hierarchy.
///
/// If [consumesKey] returns false, then not only will this action do nothing,
/// but it will stop the propagation of the key event used to trigger it to
/// other widgets in the focus chain and tell the embedding that the key wasn't
/// handled, allowing text input fields or other non-Flutter elements to receive
/// that key event. The return value of [consumesKey] can be set via the
/// `consumesKey` argument to the constructor.
///
/// This action can be bound to any [Intent].
///
/// See also:
///  - [DoNothingIntent], which is an intent that can be bound to a [KeySet] in
///    a [Shortcuts] widget to do nothing.
///  - [DoNothingAndStopPropagationIntent], which is an intent that can be bound
///    to a [KeySet] in a [Shortcuts] widget to do nothing and also stop key event
///    propagation to other key handlers in the focus chain.
class DoNothingAction extends Action<Intent> {
  /// Creates a [DoNothingAction].
  ///
  /// The optional [consumesKey] argument defaults to true.
  DoNothingAction({bool consumesKey = true}) : _consumesKey = consumesKey;

  @override
  bool consumesKey(Intent intent) => _consumesKey;
  final bool _consumesKey;

  @override
  void invoke(Intent intent) {}
}

/// An [Intent] that activates the currently focused control.
///
/// This intent is bound by default to the [LogicalKeyboardKey.space] key on all
/// platforms, and also to the [LogicalKeyboardKey.enter] key on all platforms
/// except the web, where ENTER doesn't toggle selection. On the web, ENTER is
/// bound to [ButtonActivateIntent] instead.
///
/// See also:
///
///  * [WidgetsApp.defaultShortcuts], which contains the default shortcuts used
///    in apps.
///  * [WidgetsApp.shortcuts], which defines the shortcuts to use in an
///    application (and defaults to [WidgetsApp.defaultShortcuts]).
class ActivateIntent extends Intent {
  /// Creates an intent that activates the currently focused control.
  const ActivateIntent();
}

/// An [Intent] that activates the currently focused button.
///
/// This intent is bound by default to the [LogicalKeyboardKey.enter] key on the
/// web, where ENTER can be used to activate buttons, but not toggle selection.
/// All other platforms bind [LogicalKeyboardKey.enter] to [ActivateIntent].
///
/// See also:
///
///  * [WidgetsApp.defaultShortcuts], which contains the default shortcuts used
///    in apps.
///  * [WidgetsApp.shortcuts], which defines the shortcuts to use in an
///    application (and defaults to [WidgetsApp.defaultShortcuts]).
class ButtonActivateIntent extends Intent {
  /// Creates an intent that the currently focused control, if it's a button.
  const ButtonActivateIntent();
}

/// An action that activates the currently focused control.
///
/// This is an abstract class that serves as a base class for actions that
/// activate a control. By default, is bound to [LogicalKeyboardKey.enter],
/// [LogicalKeyboardKey.gameButtonA], and [LogicalKeyboardKey.space] in the
/// default keyboard map in [WidgetsApp].
abstract class ActivateAction extends Action<ActivateIntent> { }

/// An intent that selects the currently focused control.
class SelectIntent extends Intent { }

/// An action that selects the currently focused control.
///
/// This is an abstract class that serves as a base class for actions that
/// select something. It is not bound to any key by default.
abstract class SelectAction extends Action<SelectIntent> { }

/// An [Intent] that dismisses the currently focused widget.
///
/// The [WidgetsApp.defaultShortcuts] binds this intent to the
/// [LogicalKeyboardKey.escape] and [LogicalKeyboardKey.gameButtonB] keys.
///
/// See also:
///  - [ModalRoute] which listens for this intent to dismiss modal routes
///    (dialogs, pop-up menus, drawers, etc).
class DismissIntent extends Intent {
  /// Creates an intent that dismisses the currently focused widget.
  const DismissIntent();
}

/// An action that dismisses the focused widget.
///
/// This is an abstract class that serves as a base class for dismiss actions.
abstract class DismissAction extends Action<DismissIntent> { }

/// An [Intent] that evaluates a series of specified [orderedIntents] for
/// execution.
///
/// The first intent that matches an enabled action is used.
class PrioritizedIntents extends Intent {
  /// Creates an intent that is used with [PrioritizedAction] to specify a list
  /// of intents, the first available of which will be used.
  const PrioritizedIntents({
    required this.orderedIntents,
  })  : assert(orderedIntents != null);

  /// List of intents to be evaluated in order for execution. When an
  /// [Action.isEnabled] returns true, that action will be invoked and
  /// progression through the ordered intents stops.
  final List<Intent> orderedIntents;
}

/// An [Action] that iterates through a list of [Intent]s, invoking the first
/// that is enabled.
class PrioritizedAction extends Action<PrioritizedIntents> {
  late Action<dynamic> _selectedAction;
  late Intent _selectedIntent;

  @override
  bool isEnabled(PrioritizedIntents intent) {
    final FocusNode? focus = primaryFocus;
    if  (focus == null || focus.context == null)
      return false;
    for (final Intent candidateIntent in intent.orderedIntents) {
      final Action<Intent>? candidateAction = Actions.maybeFind<Intent>(
        focus.context!,
        intent: candidateIntent,
      );
      if (candidateAction != null && candidateAction.isEnabled(candidateIntent)) {
        _selectedAction = candidateAction;
        _selectedIntent = candidateIntent;
        return true;
      }
    }
    return false;
  }

  @override
  void invoke(PrioritizedIntents intent) {
    assert(_selectedAction != null);
    assert(_selectedIntent != null);
    _selectedAction.invoke(_selectedIntent);
  }
}

mixin _OverridableActionMixin<T extends Intent> on Action<T> {
  // When debugAssertMutuallyRecursive is true, this action will throw an
  // assertion error when the override calls this action's "invoke" method and
  // the override is already being invoked from within the "invoke" method.
  bool debugAssertMutuallyRecursive = false;
  bool debugAssertIsActionEnabledMutuallyRecursive = false;
  bool debugAssertIsEnabledMutuallyRecursive = false;
  bool debugAssertConsumeKeyMutuallyRecursive = false;

  // The default action to invoke if an enabled override Action can't be found
  // using [lookupContext];
  Action<T> get defaultAction;

  // The [BuildContext] used to find the override of this [Action].
  BuildContext get lookupContext;

  // How to invoke [defaultAction], given the caller [fromAction].
  Object? invokeDefaultAction(T intent, Action<T>? fromAction, BuildContext? context);

  Action<T>? getOverrideAction({ bool declareDependency = false }) {
    final Action<T>? override = declareDependency
     ? Actions.maybeFind(lookupContext)
     : Actions._maybeFindWithoutDependingOn(lookupContext);
    assert(!identical(override, this));
    return override;
  }

  @override
  void _updateCallingAction(Action<T>? value) {
    super._updateCallingAction(value);
    defaultAction._updateCallingAction(value);
  }

  Object? _invokeOverride(Action<T> overrideAction, T intent, BuildContext? context) {
    assert(!debugAssertMutuallyRecursive);
    assert(() {
      debugAssertMutuallyRecursive = true;
      return true;
    }());
    overrideAction._updateCallingAction(defaultAction);
    final Object? returnValue = overrideAction is ContextAction<T>
      ? overrideAction.invoke(intent, context)
      : overrideAction.invoke(intent);
    overrideAction._updateCallingAction(null);
    assert(() {
      debugAssertMutuallyRecursive = false;
      return true;
    }());
    return returnValue;
  }

  @override
  Object? invoke(T intent, [BuildContext? context]) {
    final Action<T>? overrideAction = getOverrideAction();
    final Object? returnValue = overrideAction == null
      ? invokeDefaultAction(intent, callingAction, context)
      : _invokeOverride(overrideAction, intent, context);
    return returnValue;
  }

  bool isOverrideActionEnabled(Action<T> overrideAction) {
    assert(!debugAssertIsActionEnabledMutuallyRecursive);
    assert(() {
      debugAssertIsActionEnabledMutuallyRecursive = true;
      return true;
    }());
    overrideAction._updateCallingAction(defaultAction);
    final bool isOverrideEnabled = overrideAction.isActionEnabled;
    overrideAction._updateCallingAction(null);
    assert(() {
      debugAssertIsActionEnabledMutuallyRecursive = false;
      return true;
    }());
    return isOverrideEnabled;
  }

  @override
  bool get isActionEnabled {
    final Action<T>? overrideAction = getOverrideAction(declareDependency: true);
    final bool returnValue = overrideAction != null
      ? isOverrideActionEnabled(overrideAction)
      : defaultAction.isActionEnabled;
    return returnValue;
  }

  @override
  bool isEnabled(T intent) {
    assert(!debugAssertIsEnabledMutuallyRecursive);
    assert(() {
      debugAssertIsEnabledMutuallyRecursive = true;
      return true;
    }());

    final Action<T>? overrideAction = getOverrideAction();
    overrideAction?._updateCallingAction(defaultAction);
    final bool returnValue = (overrideAction ?? defaultAction).isEnabled(intent);
    overrideAction?._updateCallingAction(null);
    assert(() {
      debugAssertIsEnabledMutuallyRecursive = false;
      return true;
    }());
    return returnValue;
  }

  @override
  bool consumesKey(T intent) {
    assert(!debugAssertConsumeKeyMutuallyRecursive);
    assert(() {
      debugAssertConsumeKeyMutuallyRecursive = true;
      return true;
    }());
    final Action<T>? overrideAction = getOverrideAction();
    overrideAction?._updateCallingAction(defaultAction);
    final bool isEnabled = (overrideAction ?? defaultAction).consumesKey(intent);
    overrideAction?._updateCallingAction(null);
    assert(() {
      debugAssertConsumeKeyMutuallyRecursive = false;
      return true;
    }());
    return isEnabled;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Action<T>>('defaultAction', defaultAction));
  }
}

class _OverridableAction<T extends Intent> extends ContextAction<T> with _OverridableActionMixin<T> {
  _OverridableAction({ required this.defaultAction, required this.lookupContext }) ;

  @override
  final Action<T> defaultAction;

  @override
  final BuildContext lookupContext;

  @override
  Object? invokeDefaultAction(T intent, Action<T>? fromAction, BuildContext? context) {
    if (fromAction == null) {
      return defaultAction.invoke(intent);
    } else {
      final Object? returnValue = defaultAction.invoke(intent);
      return returnValue;
    }
  }

  @override
  ContextAction<T> _makeOverridableAction(BuildContext context) {
    return _OverridableAction<T>(defaultAction: defaultAction, lookupContext: context);
  }
}

class _OverridableContextAction<T extends Intent> extends ContextAction<T> with _OverridableActionMixin<T> {
  _OverridableContextAction({ required this.defaultAction, required this.lookupContext });

  @override
  final ContextAction<T> defaultAction;

  @override
  final BuildContext lookupContext;

  @override
  Object? _invokeOverride(Action<T> overrideAction, T intent, BuildContext? context) {
    assert(context != null);
    assert(!debugAssertMutuallyRecursive);
    assert(() {
      debugAssertMutuallyRecursive = true;
      return true;
    }());

    // Wrap the default Action together with the calling context in case
    // overrideAction is not a ContextAction and thus have no access to the
    // calling BuildContext.
    final Action<T> wrappedDefault = _ContextActionToActionAdapter<T>(invokeContext: context!, action: defaultAction);
    overrideAction._updateCallingAction(wrappedDefault);
    final Object? returnValue = overrideAction is ContextAction<T>
      ? overrideAction.invoke(intent, context)
      : overrideAction.invoke(intent);
    overrideAction._updateCallingAction(null);

    assert(() {
      debugAssertMutuallyRecursive = false;
      return true;
    }());
    return returnValue;
  }

  @override
  Object? invokeDefaultAction(T intent, Action<T>? fromAction, BuildContext? context) {
    if (fromAction == null) {
      return defaultAction.invoke(intent, context);
    } else {
      final Object? returnValue = defaultAction.invoke(intent, context);
      return returnValue;
    }
  }

  @override
  ContextAction<T> _makeOverridableAction(BuildContext context) {
    return _OverridableContextAction<T>(defaultAction: defaultAction, lookupContext: context);
  }
}

class _ContextActionToActionAdapter<T extends Intent> extends Action<T> {
  _ContextActionToActionAdapter({required this.invokeContext, required this.action});

  final BuildContext invokeContext;
  final ContextAction<T> action;

  @override
  void _updateCallingAction(Action<T>? value) {
    action._updateCallingAction(value);
  }

  @override
  Action<T>? get callingAction => action.callingAction;

  @override
  bool isEnabled(T intent) => action.isEnabled(intent);

  @override
  bool get isActionEnabled => action.isActionEnabled;

  @override
  bool consumesKey(T intent) => action.consumesKey(intent);

  @override
  void addActionListener(ActionListenerCallback listener) {
    super.addActionListener(listener);
    action.addActionListener(listener);
  }

  @override
  void removeActionListener(ActionListenerCallback listener) {
    super.removeActionListener(listener);
    action.removeActionListener(listener);
  }

  @override
  @protected
  void notifyActionListeners() => action.notifyActionListeners();

  @override
  Object? invoke(T intent) => action.invoke(intent, invokeContext);
}
