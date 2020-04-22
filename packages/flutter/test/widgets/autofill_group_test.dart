// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AutofillGroup has the right clients', (WidgetTester tester) async {
    const Key outerKey = Key('outer');
    const Key innerKey = Key('inner');

    const TextField client1 = TextField(autofillHints: <String>['1']);
    const TextField client2 = TextField(autofillHints: <String>['2']);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutofillGroup(
            key: outerKey,
            child: Column(children: <Widget>[
              client1,
              AutofillGroup(
                key: innerKey,
                child: Column(children: const <Widget>[client2, TextField()]),
              ),
            ]),
          ),
        ),
      ),
    );

    final AutofillGroupState innerState = tester.state<AutofillGroupState>(find.byKey(innerKey));
    final AutofillGroupState outerState = tester.state<AutofillGroupState>(find.byKey(outerKey));

    final EditableTextState clientState1 = tester.state<EditableTextState>(
      find.descendant(of: find.byWidget(client1), matching: find.byType(EditableText)),
    );
    final EditableTextState clientState2 = tester.state<EditableTextState>(
      find.descendant(of: find.byWidget(client2), matching: find.byType(EditableText)),
    );

    expect(outerState.autofillClients, <EditableTextState>[clientState1]);
    expect(innerState.autofillClients, <EditableTextState>[clientState2]);
  });

  testWidgets('new clients can be added & removed to a scope', (WidgetTester tester) async {
    const Key scopeKey = Key('scope');

    final List<String> hints = <String>[];

    const TextField client1 = TextField(autofillHints: <String>['1']);
    final TextField client2 = TextField(autofillHints: hints);

    StateSetter setState;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutofillGroup(
            key: scopeKey,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return Column(children: <Widget>[client1, client2]);
              },
            ),
          ),
        ),
      ),
    );

    final AutofillGroupState scopeState = tester.state<AutofillGroupState>(find.byKey(scopeKey));

    final EditableTextState clientState1 = tester.state<EditableTextState>(
      find.descendant(of: find.byWidget(client1), matching: find.byType(EditableText)),
    );
    final EditableTextState clientState2 = tester.state<EditableTextState>(
      find.descendant(of: find.byWidget(client2), matching: find.byType(EditableText)),
    );

    expect(scopeState.autofillClients, <EditableTextState>[clientState1]);

    // Add to scope.
    setState(() { hints.add('2'); });

    await tester.pump();

    expect(scopeState.autofillClients.length, 2);
    expect(scopeState.autofillClients, contains(clientState1));
    expect(scopeState.autofillClients, contains(clientState2));

    // Remove from scope again.
    setState(() { hints.clear(); });

    await tester.pump();

    expect(scopeState.autofillClients, <EditableTextState>[clientState1]);
  });

  testWidgets('AutofillGroup has the right clients after reparenting', (WidgetTester tester) async {
    const Key outerKey = Key('outer');
    const Key innerKey = Key('inner');
    final GlobalKey keyClient3 = GlobalKey();

    const TextField client1 = TextField(autofillHints: <String>['1']);
    const TextField client2 = TextField(autofillHints: <String>['2']);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutofillGroup(
            key: outerKey,
            child: Column(children: <Widget>[
              client1,
              AutofillGroup(
                key: innerKey,
                child: Column(children: <Widget>[
                  client2,
                  TextField(key: keyClient3, autofillHints: const <String>['3']),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );

    final AutofillGroupState innerState = tester.state<AutofillGroupState>(find.byKey(innerKey));
    final AutofillGroupState outerState = tester.state<AutofillGroupState>(find.byKey(outerKey));

    final EditableTextState clientState1 = tester.state<EditableTextState>(
      find.descendant(of: find.byWidget(client1), matching: find.byType(EditableText)),
    );
    final EditableTextState clientState2 = tester.state<EditableTextState>(
      find.descendant(of: find.byWidget(client2), matching: find.byType(EditableText)),
    );

    final EditableTextState clientState3 = tester.state<EditableTextState>(
      find.descendant(of: find.byKey(keyClient3), matching: find.byType(EditableText)),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutofillGroup(
            key: outerKey,
            child: Column(children: <Widget>[
              client1,
              TextField(key: keyClient3, autofillHints: const <String>['3']),
              AutofillGroup(
                key: innerKey,
                child: Column(children: const <Widget>[client2]),
              ),
            ]),
          ),
        ),
      ),
    );

    expect(outerState.autofillClients.length, 2);
    expect(outerState.autofillClients, contains(clientState1));
    expect(outerState.autofillClients, contains(clientState3));
    expect(innerState.autofillClients, <EditableTextState>[clientState2]);
  });
}
