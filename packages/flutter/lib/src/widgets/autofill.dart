// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'framework.dart';

export 'package:flutter/services.dart' show AutofillHints;

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
