// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/services.dart';
import 'framework.dart';

export 'package:flutter/services.dart' show AutofillHints;

/// Predefined autofill context clean up actions.
enum AutofillContextAction {
  /// Destroys the current autofill context after informing the platform to save
  /// the user input from it.
  ///
  /// Corresponds to calling [TextInput.finishAutofillContext] with
  /// `shouldSave == true`.
  commit,

  /// Destroys the current autofill context without saving the user input.
  ///
  /// Corresponds to calling [TextInput.finishAutofillContext] with
  /// `shouldSave == false`.
  cancel,
}

/// An [AutofillScope] widget that groups [AutofillClient]s together.
///
/// [AutofillClient]s that share the same closest [AutofillGroup] ancestor must
/// be built together, and they be will be autofilled together.
///
/// {@macro flutter.services.autofill.AutofillScope}
///
/// The [AutofillGroup] widget only knows about [AutofillClient]s registered to
/// it using the [AutofillGroupState.register] API. Typically, [AutofillGroup]
/// will not pick up [AutofillClient]s that are not mounted, for example, an
/// [AutofillClient] within a [Scrollable] that has never been scrolled into the
/// viewport. To workaround this problem, ensure clients in the same
/// [AutofillGroup] are built together.
///
/// The topmost [AutofillGroup] widgets (the ones that are closest to the root
/// widget) can be used to clean up the current autofill context when the
/// current autofill context is no longer relevant.
///
/// {@macro flutter.services.autofill.autofillContext}
///
/// By default, [onDisposeAction] is set to [AutofillContextAction.commit], in
/// which case when any of the topmost [AutofillGroup]s is being disposed, the
/// platform will be informed to save the user input from the current autofill
/// context, then the current autofill context will be destroyed, to free
/// resources. You can, for example, wrap a route that contains a [Form] full of
/// autofillable input fields in an [AutofillGroup], so the user input of the
/// [Form] can be saved for future autofill by the platform.
///
/// {@tool dartpad --template=stateful_widget_scaffold}
///
/// An example form with autofillable fields grouped into different
/// `AutofillGroup`s.
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
///        // The address fields are grouped together as some platforms are
///        // capable of autofilling all of these fields in one go.
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
///        // The credit card number and the security code are grouped together
///        // as some platforms are capable of autofilling both fields.
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
///
/// See also:
///
/// * [AutofillContextAction], an enum that contains predefined autofill context
///   clean up actions to be run when a topmost [AutofillGroup] is disposed.
class AutofillGroup extends StatefulWidget {
  /// Creates a scope for autofillable input fields.
  ///
  /// The [child] argument must not be null.
  const AutofillGroup({
    Key key,
    @required this.child,
    this.onDisposeAction = AutofillContextAction.commit,
  }) : assert(child != null),
       super(key: key);

  /// Returns the closest [AutofillGroupState] which encloses the given context.
  ///
  /// {@macro flutter.widgets.autofill.AutofillGroupState}
  ///
  /// See also:
  ///
  /// * [EditableTextState], where this method is used to retrieve the closest
  ///   [AutofillGroupState].
  static AutofillGroupState of(BuildContext context) {
    final _AutofillScope scope = context.dependOnInheritedWidgetOfExactType<_AutofillScope>();
    return scope?._scope;
  }

  /// {@macro flutter.widgets.child}
  final Widget child;

  /// The [AutofillContextAction] to be run when this [AutofillGroup] is the
  /// topmost [AutofillGroup] and it's being disposed, in order to clean up the
  /// current autofill context.
  ///
  /// {@macro flutter.services.autofill.autofillContext}
  ///
  /// Defaults to [AutofillContextAction.commit], which prompts the platform to
  /// save the user input and destroy the current autofill context. No action
  /// will be taken if [onDisposeAction] is set to null.
  final AutofillContextAction onDisposeAction;

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
/// The [AutofillGroupState] class also provides an [AutofillGroupState.attach]
/// method that can be called by [TextInputClient]s that support autofill,
/// instead of [TextInput.attach], to create a [TextInputConnection] to interact
/// with the platform's text input system.
/// {@endtemplate}
///
/// Typically obtained using [AutofillGroup.of].
class AutofillGroupState extends State<AutofillGroup> with AutofillScopeMixin {
  final Map<String, AutofillClient> _clients = <String, AutofillClient>{};

  // Whether this AutofillGroup widget is the topmost AutofillGroup (i.e., it
  // has no AutofillGroup ancestor). Each topmost AutofillGroup runs its
  // `AutofillGroup.onDisposeAction` when it gets disposed.
  bool _isTopmostAutofillGroup = false;

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

  /// Removes an [AutofillClient] with the given `autofillId` from this
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isTopmostAutofillGroup = AutofillGroup.of(context) == null;
  }

  @override
  Widget build(BuildContext context) {
    return _AutofillScope(
      autofillScopeState: this,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    super.dispose();

    if (!_isTopmostAutofillGroup || widget.onDisposeAction == null)
      return;
    switch (widget.onDisposeAction) {
      case AutofillContextAction.cancel:
        TextInput.finishAutofillContext(shouldSave: false);
        break;
      case AutofillContextAction.commit:
        TextInput.finishAutofillContext(shouldSave: true);
        break;
    }
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
