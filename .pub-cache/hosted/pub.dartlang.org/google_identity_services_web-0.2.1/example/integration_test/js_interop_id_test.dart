// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_identity_services_web/id.dart';
import 'package:integration_test/integration_test.dart';
import 'package:js/js.dart';

import 'src/dom.dart';
import 'utils.dart' as utils;

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Load web/mock-gis.js in the page
    await utils.installGisMock();
  });

  group('renderButton', () {
    testWidgets('supports a js-interop target from any library', (_) async {
      final DomElement target = createDomElement('div');

      id.renderButton(target);

      final DomElement? button = target.querySelector('button');
      expect(button, isNotNull);
    });
  });

  group('prompt', () {
    testWidgets('supports a moment notification callback', (_) async {
      id.initialize(IdConfiguration(client_id: 'testing_1-2-3'));

      final StreamController<PromptMomentNotification> controller =
          StreamController<PromptMomentNotification>();

      id.prompt(allowInterop(controller.add));

      final PromptMomentNotification moment = await controller.stream.first;

      // These defaults are set in mock-gis.js
      expect(moment.getMomentType(), MomentType.skipped);
      expect(moment.getSkippedReason(), MomentSkippedReason.user_cancel);
    });

    testWidgets('calls config callback with credential response', (_) async {
      const String expected = 'should_be_a_proper_jwt_token';
      utils.setMockCredentialResponse(expected);

      final StreamController<CredentialResponse> controller =
          StreamController<CredentialResponse>();

      id.initialize(IdConfiguration(
        client_id: 'testing_1-2-3',
        callback: allowInterop(controller.add),
      ));

      id.prompt();

      final CredentialResponse response = await controller.stream.first;

      expect(response.credential, expected);
    });
  });
}
