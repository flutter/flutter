// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form.dart' show FormState;
import 'framework.dart';
import 'navigator.dart' show Route;

export 'package:flutter/services.dart' show AutofillHints;

typedef OnAutofillGroupDisposeCallback = bool Function({ BuildContext from });

/// An [AutofillScope] widget that groups [AutofillClient]s together.
///
/// [AutofillClient]s within the same [AutofillScope] must be built together, and
/// they be will be autofilled together.
///
/// {@macro flutter.services.autofill.AutofillScope}
///
/// The [AutofillGroup] widget only knows about [AutofillClient]s registered to
/// it using the [AutofillGroupState.register] API. Typically, [AutofillGroup]
/// will not pick up [AutofillClient]s that are not mounted, for example, an
/// [AutofillClient] within a [Scrollable] that has never been scrolled into the
/// viewport. To workaround this problem, ensure clients in the same [AutofillGroup]
/// are built together:
///
/// {@tool dartpad --template=stateful_widget_scaffold}
///
/// An example form with autofillable fields grouped into different `AutofillGroup`s.
///
/// ```dart
///  bool isSameAddress = true;
///  final TextEditingController shippingAddress1 = TextEditingController();
///  final TextEditingController shippingAddress2 = TextEditingController();
///  final TextEditingController billingAddress1 = TextEditingController();
///  final TextEditingController billingAddress2 = TextEditingController();
///
///  final TextEditingController creditCardNumber = TextEditingController();
///  final TextEditingController creditCardSecurityCode = TextEditingController();
///
///  final TextEditingController phoneNumber = TextEditingController();
///
///  @override
///  Widget build(BuildContext context) {
///    return ListView(
///      children: <Widget>[
///        const Text('Shipping address'),
///        // The address fields are grouped together as some platforms are capable
///        // of autofilling all these fields in one go.
///        AutofillGroup(
///          child: Column(
///            children: <Widget>[
///              TextField(
///                controller: shippingAddress1,
///                autofillHints: <String>[AutofillHints.streetAddressLine1],
///              ),
///              TextField(
///                controller: shippingAddress2,
///                autofillHints: <String>[AutofillHints.streetAddressLine2],
///              ),
///            ],
///          ),
///        ),
///        const Text('Billing address'),
///        Checkbox(
///          value: isSameAddress,
///          onChanged: (bool newValue) {
///            setState(() { isSameAddress = newValue; });
///          },
///        ),
///        // Again the address fields are grouped together for the same reason.
///        if (!isSameAddress) AutofillGroup(
///          child: Column(
///            children: <Widget>[
///              TextField(
///                controller: billingAddress1,
///                autofillHints: <String>[AutofillHints.streetAddressLine1],
///              ),
///              TextField(
///                controller: billingAddress2,
///                autofillHints: <String>[AutofillHints.streetAddressLine2],
///              ),
///            ],
///          ),
///        ),
///        const Text('Credit Card Information'),
///        // The credit card number and the security code are grouped together as
///        // some platforms are capable of autofilling both fields.
///        AutofillGroup(
///          child: Column(
///            children: <Widget>[
///              TextField(
///                controller: creditCardNumber,
///                autofillHints: <String>[AutofillHints.creditCardNumber],
///              ),
///              TextField(
///                controller: creditCardSecurityCode,
///                autofillHints: <String>[AutofillHints.creditCardSecurityCode],
///              ),
///            ],
///          ),
///        ),
///        const Text('Contact Phone Number'),
///        // The phone number field can still be autofilled despite lacking an
///        // `AutofillScope`.
///        TextField(
///          controller: phoneNumber,
///          autofillHints: <String>[AutofillHints.telephoneNumber],
///        ),
///      ],
///    );
///  }
/// ```
/// {@end-tool}
class AutofillGroup extends StatefulWidget {
  /// Creates a scope for autofillable input fields.
  ///
  /// The [child] argument must not be null.
  const AutofillGroup({
    Key key,
    @required this.child,
  }) : assert(child != null),
       super(key: key);

  /// Returns the closest [AutofillGroupState] which encloses the given context.
  ///
  /// {@macro flutter.widgets.autofill.AutofillGroupState}
  ///
  /// See also:
  ///
  /// * [EditableTextState], where this method is used to retrive the closest
  ///   [AutofillGroupState].
  static AutofillGroupState of(BuildContext context) {
    final _AutofillScope scope = context.dependOnInheritedWidgetOfExactType<_AutofillScope>();
    return scope?._scope;
  }

  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  AutofillGroupState createState() => AutofillGroupState();
}

/// State associated with an [AutofillGroup] widget.
///
/// {@template flutter.widgets.autofill.AutofillGroupState}
/// An [AutofillGroupState] can be used to register an [AutofillClient] when it
/// enters this [AutofillGroup] (for example, when an [EditableText] is mounted or
/// reparented onto the [AutofillGroup]'s subtree), and unregister an
/// [AutofillClient] when it exits (for example, when an [EditableText] gets
/// unmounted or reparented out of the [AutofillGroup]'s subtree).
///
/// The [AutofillGroupState] class also provides an [attach] method that can be
/// called by [TextInputClient]s that support autofill, instead of
/// [TextInputClient.attach], to create a [TextInputConnection] to interact with
/// the platform's text input system.
/// {@endtemplate}
///
/// Typically obtained using [AutofillGroup.of].
class AutofillGroupState extends State<AutofillGroup> with AutofillScopeMixin {
  final Map<String, AutofillClient> _clients = <String, AutofillClient>{};

  @override
  AutofillClient getAutofillClient(String tag) => _clients[tag];

  @override
  Iterable<AutofillClient> get autofillClients {
    return _clients.values
      .where((AutofillClient client) => client?.textInputConfiguration?.autofillConfiguration != null);
  }

  /// Adds the [AutofillClient] to this [AutofillGroup].
  ///
  /// Typically, this is called by [TextInputClient]s that support autofill (for
  /// example, [EditableTextState]) in [State.didChangeDependencies], when the
  /// input field should be registered to a new [AutofillGroup].
  ///
  /// See also:
  ///
  /// * [EditableTextState.didChangeDependencies], where this method is called
  ///   to update the current [AutofillScope] when needed.
  void register(AutofillClient client) {
    assert(client != null);
    _clients.putIfAbsent(client.autofillId, () => client);
  }

  /// Removes an [AutofillClient] with the given [autofillId] from this
  /// [AutofillGroup].
  ///
  /// Typically, this should be called by autofillable [TextInputClient]s in
  /// [State.dispose] and [State.didChangeDependencies], when the input field
  /// needs to be removed from the [AutofillGroup] it is currently registered to.
  ///
  /// See also:
  ///
  /// * [EditableTextState.didChangeDependencies], where this method is called
  ///   to unregister from the previous [AutofillScope].
  /// * [EditableTextState.dispose], where this method is called to unregister
  ///   from the current [AutofillScope] when the widget is about to be removed
  ///   from the tree.
  void unregister(String autofillId) {
    assert(autofillId != null && _clients.containsKey(autofillId));
    _clients.remove(autofillId);
  }

  @override
  Widget build(BuildContext context) {
    return _AutofillScope(
      autofillScopeState: this,
      child: widget.child,
    );
  }
}

class _AutofillScope extends InheritedWidget {
  const _AutofillScope({
    Key key,
    Widget child,
    AutofillGroupState autofillScopeState,
  }) : _scope = autofillScopeState,
       super(key: key, child: child);

  final AutofillGroupState _scope;

  AutofillGroup get client => _scope.widget;

  @override
  bool updateShouldNotify(_AutofillScope old) => _scope != old._scope;
}

/// An [InheritedWidget] that configures its descendant [Navigator]s and [Form]s,
/// as to whether the current autofill context should be saved or discarded, or
/// no action should be taken at all, when the [Navigator]s' [Route]s change, or
/// when the [Form] is saved.
///
/// {@macro flutter.services.autofill.autofillContext}
///
/// Set [AutofillContextLifecycleAction.globalLifecycleDelegate] if you wish to
/// set up a global [AutofillContextLifecycleDelegate] for the entire app.
///
/// The default [globalLifecycleDelegate] saves the current autofill context
/// when there's a route change,
///
///
/// See also:
///
/// * [AutofillContextLifecycleDelegate], the configuration data this
///   [InheritWidget] carries.
///
/// * [TextInput.finishAutofillContext],
class AutofillContextLifecycleAction extends InheritedWidget {
  /// Creates a widget that provides its descendants with an
  /// [AutofillContextLifecycleDelegate], which cleans up the current autofill
  /// context on certian lifecycle events of [Router] and [Form].
  const AutofillContextLifecycleAction({
    Key key,
    Widget child,
    this.lifecycleDelegate,
  }): super(key: key, child: child);

  /// The [AutofillContextLifecycleDelegate] that descendant
  final AutofillContextLifecycleDelegate lifecycleDelegate;

  /// The [AutofillContextLifecycleDelegate] to fall back to, when there's no
  /// enclosing [AutofillContextLifecycleAction] in the context.
  ///
  /// This value can be changed to modify the global configuration. Changes
  /// apply immediately: the new [globalLifecycleDelegate] takes effect starting
  /// from the next monitored lifecycle event.
  ///
  /// Must not be null.
  static AutofillContextLifecycleDelegate get globalLifecycleDelegate => _globalLifecycleDelegate;
  static AutofillContextLifecycleDelegate _globalLifecycleDelegate = const AutofillContextLifecycleDelegate();
  static set globalLifecycleDelegate(AutofillContextLifecycleDelegate newDelegate) {
    assert(newDelegate != null);
    if (_globalLifecycleDelegate != newDelegate)
      _globalLifecycleDelegate = newDelegate;
  }

  /// The [AutofillContextLifecycleDelegate] from the closest
  /// [AutofillContextLifecycleAction] widget that encloses the given [context],
  /// or the default configuration [AutofillContextLifecycleAction.globalLifecycleDelegate]
  /// if the given [context] does not contain an [AutofillContextLifecycleDelegate].
  static AutofillContextLifecycleDelegate of(BuildContext context) {
    return context?.dependOnInheritedWidgetOfExactType<AutofillContextLifecycleAction>()?.lifecycleDelegate ?? globalLifecycleDelegate;
  }

  // Changing delegates shouldn't make anything other than the widget itself
  // rebuild.
  @override
  bool updateShouldNotify(covariant AutofillContextLifecycleAction oldWidget) => false;
}

/// Configures whether the current autofill context should be saved or discarded
/// , or no action should be taken at all, when [Navigator]s and [Form]s
/// configured by this [AutofillContextLifecycleDelegate] observes certain types
/// of events.
///
/// Typically retrieved using [AutofillContextLifecycleAction.of].
///
/// The default implementation signals the platform to save the current autofill
/// context (before discarding it), when any of the affected [Form]s is saved,
/// or any of the affected [Navigator]s pushes/pops/removes an opaque
/// [ModalRoute], or the current route is replaced with an opaque [ModalRoute].
class AutofillContextLifecycleDelegate {
  /// Creates a delegate object that can be used to clean up the current
  /// autofill context at proper times, for example, when [Route]s change or
  /// when [Form]s are saved.
  const AutofillContextLifecycleDelegate();

  /// The action needs to be taken after [FormState.save] is called on
  /// [savedForm].
  ///
  /// The default implementation saves the current autofill context.
  void onFormSave(FormState savedForm) {
    TextInput.finishAutofillContext(shouldSave: true);
  }

  /// The action to take when any [Navigator] in the app pushed [route], on top
  /// of the previous active route [previousRoute].
  ///
  /// {@macro flutter.widgets.navigatorObserver.didPush}
  ///
  /// The default implementation saves the current autofill context if [route]
  /// is an opaque [ModalRoute].
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    // TODO(LongCatIsLooong): Ideally we want to set the current context aside
    // and start a new autofill context for the new route we pushed. This
    // doesn't seem to be possible on Android currently.
    if (route is ModalRoute && route.opaque)
      TextInput.finishAutofillContext(shouldSave: true);
  }

  /// The action to take when a [Navigator] in the app popped [route].
  ///
  /// {@macro flutter.widgets.navigatorObserver.didPop}
  ///
  /// The default implementation saves the current autofill context if [route]
  /// is an opaque [ModalRoute].
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route is ModalRoute && route.opaque)
      TextInput.finishAutofillContext(shouldSave: true);
  }

  /// The action to take when any [Navigator] in the app removed [route], and
  /// its current route is [previousRoute].
  ///
  /// {@macro flutter.widgets.navigatorObserver.didRemove}
  ///
  /// The default implementation saves the current autofill context if [route]
  /// is an opaque [ModalRoute].
  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route is ModalRoute && route.opaque)
      TextInput.finishAutofillContext(shouldSave: true);
  }

  /// The action to take when any [Navigator] in the app replaced [oldRoute]
  /// with [newRoute].
  ///
  /// The default implementation saves the current autofill context if
  /// [newRoute] or [oldRoute] is an opaque [ModalRoute].
  void didReplace({ Route<dynamic> newRoute, Route<dynamic> oldRoute }) {
    if ((oldRoute is ModalRoute && oldRoute.opaque) || (newRoute is ModalRoute && newRoute.opaque))
      TextInput.finishAutofillContext(shouldSave: true);
  }
}

