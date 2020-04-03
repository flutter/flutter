// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'text_input_test.dart' show FakeTextChannel, FakeTextInputClient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextInput message channels', () {
    FakeTextChannel fakeTextChannel;
    FakeAutofillScope scope;

    setUp(() {
      fakeTextChannel = FakeTextChannel((MethodCall call) async {});
      TextInput.setChannel(fakeTextChannel);
      scope ??= FakeAutofillScope();
      scope.autofillClients = <AutofillClient>[];
    });

    tearDown(() {
      TextInputConnection.debugResetId();
      TextInput.setChannel(SystemChannels.textInput);
    });

    test('text input client handler responds to reattach with setClient', () async {
      final FakeAutofillClient client1 = FakeAutofillClient(const TextEditingValue(text: 'test1'));
      final FakeAutofillClient client2 = FakeAutofillClient(const TextEditingValue(text: 'test2'));

      client1.textInputConfiguration = TextInputConfiguration(
        autofillConfiguration: AutofillConfiguration(
          uniqueIdentifier: 'id_client1',
          autofillHints: const <String>['client1'],
          currentEditingValue: client1.currentTextEditingValue,
        ),
      );

      client2.textInputConfiguration = TextInputConfiguration(
        autofillConfiguration: AutofillConfiguration(
          uniqueIdentifier: 'id_client2',
          autofillHints: const <String>['client2'],
          currentEditingValue: client2.currentTextEditingValue,
        ),
      );

      scope.autofillClients.add(client1);
      scope.autofillClients.add(client2);
      client1.currentAutofillScope = scope;
      client2.currentAutofillScope = scope;

      scope.attach(client1, client1.textInputConfiguration);

      final Map<String, dynamic> expectedConfiguration = client1.textInputConfiguration.toJson();
      expectedConfiguration['allFields'] = <Map<String, dynamic>>[
        client1.textInputConfiguration.toJson(),
        client2.textInputConfiguration.toJson(),
      ];

      fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
        MethodCall('TextInput.setClient', <dynamic>[1, expectedConfiguration]),
      ]);

      const TextEditingValue text2 = TextEditingValue(text: 'Text 2');
      fakeTextChannel.incoming(MethodCall(
        'TextInputClient.updateEditingStateWithTag',
        <dynamic>[0, <String, dynamic>{ 'id_client2': text2.toJSON() }],
      ));

      expect(client2.currentTextEditingValue, text2);
    });
  });
}

class FakeAutofillClient extends FakeTextInputClient with AutofillClientMixin implements AutofillTrigger {
  FakeAutofillClient(TextEditingValue currentTextEditingValue): super(currentTextEditingValue);

  @override
  TextInputConfiguration textInputConfiguration;

  @override
  void updateEditingValue(TextEditingValue newEditingValue) {
    currentTextEditingValue = newEditingValue;
  }

  @override
  AutofillScope currentAutofillScope;

  @override
  TextInputConfiguration get configuration => textInputConfiguration;
}

class FakeAutofillScope with AutofillScopeMixin implements AutofillScope {
  @override
  List<AutofillClient> autofillClients;
}
