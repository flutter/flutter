// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'framework.dart';

export 'package:flutter/services.dart' show AutofillHints;

/// An [AutofillScope] widget that groups [AutofillClient]s together.
/// [AutofillClient]s within the same [AutofillScope] will be autofilled together.
///
/// {@macro flutter.services.autofill.AutofillScope}
///
/// The [AutofillGroup] widget finds its [AutofillClient]s by traversing its
/// subtree using [Element.visitChildElements], looking for [Element]s or [State]s
/// that are [AutofillClient]s. Other [AutofillGroup] nodes and their subtrees
/// will be ignored in this process. As a result, [AutofillGroup] will not pick
/// up [AutofillClient]s that are not mounted, for example, an [AutofillClient]
/// within a [Scrollable] that has never been scrolled into the viewport. To
/// workaround this problem, ensure clients in the same [AutofillGroup] are built
/// together:
///
/// {@tool dartpad --template=stateful_widget_material}
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

  /// Returns the closest [AutofillScope] which encloses the given context.
  ///
  /// In order to interact with the platform's autofill mechanism,
  /// [AutofillTrigger]s need to call [AutofillScope.attach] on their closest
  /// [AutofillScope], instead of calling [TextInputClient.attach].
  static AutofillScope of(BuildContext context) {
    final _AutofillScope scope = context.dependOnInheritedWidgetOfExactType<_AutofillScope>();
    return scope?._scope;
  }

  /// {@macro flutter.widgets.child}
  final Widget child;

  @override
  _AutofillGroupState createState() => _AutofillGroupState();
}

class _AutofillGroupState extends State<AutofillGroup> with AutofillScopeMixin {
  @override
  Iterable<AutofillClient> get autofillClients {
    final List<AutofillClient> clients = <AutofillClient>[];
    void visit(Element element) {
      if (element is AutofillScope)
        return;
      if (element is AutofillClient) {
        clients.add(element as AutofillClient);
      } else if (element is StatefulElement && element.state is AutofillClient) {
        clients.add(element.state as AutofillClient);
      } else {
        element.visitChildElements(visit);
      }
    }

    context.visitChildElements(visit);
    return clients;
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
    _AutofillGroupState autofillScopeState,
  }) : _scope = autofillScopeState,
       super(key: key, child: child);

  final _AutofillGroupState _scope;

  AutofillGroup get client => _scope.widget;

  @override
  bool updateShouldNotify(_AutofillScope old) => _scope != old._scope;
}
