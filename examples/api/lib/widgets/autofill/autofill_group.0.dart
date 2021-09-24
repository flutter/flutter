// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Template: dev/snippets/config/templates/stateful_widget_scaffold.tmpl
//
// Comment lines marked with "▼▼▼" and "▲▲▲" are used for authoring
// of samples, and may be ignored if you are just exploring the sample.

// Flutter code sample for AutofillGroup
//
//***************************************************************************
//* ▼▼▼▼▼▼▼▼ description ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

// An example form with autofillable fields grouped into different
// `AutofillGroup`s.

//* ▲▲▲▲▲▲▲▲ description ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//***************************************************************************

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatefulWidget(),
      ),
    );
  }
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
//********************************************************************
//* ▼▼▼▼▼▼▼▼ code ▼▼▼▼▼▼▼▼ (do not modify or remove section marker)

  bool isSameAddress = true;
  final TextEditingController shippingAddress1 = TextEditingController();
  final TextEditingController shippingAddress2 = TextEditingController();
  final TextEditingController billingAddress1 = TextEditingController();
  final TextEditingController billingAddress2 = TextEditingController();

  final TextEditingController creditCardNumber = TextEditingController();
  final TextEditingController creditCardSecurityCode = TextEditingController();

  final TextEditingController phoneNumber = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const Text('Shipping address'),
        // The address fields are grouped together as some platforms are
        // capable of autofilling all of these fields in one go.
        AutofillGroup(
          child: Column(
            children: <Widget>[
              TextField(
                controller: shippingAddress1,
                autofillHints: const <String>[AutofillHints.streetAddressLine1],
              ),
              TextField(
                controller: shippingAddress2,
                autofillHints: const <String>[AutofillHints.streetAddressLine2],
              ),
            ],
          ),
        ),
        const Text('Billing address'),
        Checkbox(
          value: isSameAddress,
          onChanged: (bool? newValue) {
            if (newValue != null) {
              setState(() {
                isSameAddress = newValue;
              });
            }
          },
        ),
        // Again the address fields are grouped together for the same reason.
        if (!isSameAddress)
          AutofillGroup(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: billingAddress1,
                  autofillHints: const <String>[
                    AutofillHints.streetAddressLine1
                  ],
                ),
                TextField(
                  controller: billingAddress2,
                  autofillHints: const <String>[
                    AutofillHints.streetAddressLine2
                  ],
                ),
              ],
            ),
          ),
        const Text('Credit Card Information'),
        // The credit card number and the security code are grouped together
        // as some platforms are capable of autofilling both fields.
        AutofillGroup(
          child: Column(
            children: <Widget>[
              TextField(
                controller: creditCardNumber,
                autofillHints: const <String>[AutofillHints.creditCardNumber],
              ),
              TextField(
                controller: creditCardSecurityCode,
                autofillHints: const <String>[
                  AutofillHints.creditCardSecurityCode
                ],
              ),
            ],
          ),
        ),
        const Text('Contact Phone Number'),
        // The phone number field can still be autofilled despite lacking an
        // `AutofillScope`.
        TextField(
          controller: phoneNumber,
          autofillHints: const <String>[AutofillHints.telephoneNumber],
        ),
      ],
    );
  }

//* ▲▲▲▲▲▲▲▲ code ▲▲▲▲▲▲▲▲ (do not modify or remove section marker)
//********************************************************************

}
