// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

const StandardMessageCodec codec = StandardMessageCodec();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  late AccessibilityAnnouncements accessibilityAnnouncements;

  setUp(() {
    final DomElement announcementsHost = createDomElement('flt-announcement-host');
    accessibilityAnnouncements = AccessibilityAnnouncements(hostElement: announcementsHost);
    setLiveMessageDurationForTest(const Duration(milliseconds: 10));
    expect(
      announcementsHost.querySelector('flt-announcement-polite'),
      accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite),
    );
    expect(
      announcementsHost.querySelector('flt-announcement-assertive'),
      accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive),
    );
  });

  tearDown(() async {
    await Future<void>.delayed(liveMessageDuration * 2);
  });

  group('$AccessibilityAnnouncements', () {
    ByteData? encodeMessageOnly({required String message}) {
      return codec.encodeMessage(<dynamic, dynamic>{
        'data': <dynamic, dynamic>{'message': message},
      });
    }

    void sendAnnouncementMessage({required String message, int? assertiveness}) {
      accessibilityAnnouncements.handleMessage(
        codec,
        codec.encodeMessage(<dynamic, dynamic>{
          'data': <dynamic, dynamic>{'message': message, 'assertiveness': assertiveness},
        }),
      );
    }

    void expectMessages({String polite = '', String assertive = ''}) {
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, polite);
      expect(
        accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text,
        assertive,
      );
    }

    void expectNoMessages() => expectMessages();

    // Small delay to allow Timer(Duration.zero) callbacks to execute
    Future<void> waitForNextEventLoop() => Future<void>.delayed(Duration.zero);

    test('Default value of aria-live is polite when assertiveness is not specified', () async {
      accessibilityAnnouncements.handleMessage(codec, encodeMessageOnly(message: 'polite message'));
      await waitForNextEventLoop();
      expectMessages(polite: 'polite message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('aria-live is assertive when assertiveness is set to 1', () async {
      sendAnnouncementMessage(message: 'assertive message', assertiveness: 1);
      await waitForNextEventLoop();
      expectMessages(assertive: 'assertive message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('aria-live is polite when assertiveness is null', () async {
      sendAnnouncementMessage(message: 'polite message');
      await waitForNextEventLoop();
      expectMessages(polite: 'polite message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('aria-live is polite when assertiveness is set to 0', () async {
      sendAnnouncementMessage(message: 'polite message', assertiveness: 0);
      await waitForNextEventLoop();
      expectMessages(polite: 'polite message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('Rapid-fire messages are each announced', () async {
      // Send first message
      sendAnnouncementMessage(message: 'Hello');
      await waitForNextEventLoop();
      expectMessages(polite: 'Hello');

      // Wait for first message to clear
      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();

      // Send second message
      sendAnnouncementMessage(message: 'There');
      await waitForNextEventLoop();
      expectMessages(polite: 'There\u00A0');

      // Wait for second message to clear
      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('Repeated announcements are modified to ensure screen readers announce them', () async {
      sendAnnouncementMessage(message: 'Hello');
      await waitForNextEventLoop();
      expectMessages(polite: 'Hello');
      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();

      sendAnnouncementMessage(message: 'Hello');
      await waitForNextEventLoop();
      expectMessages(polite: 'Hello\u00A0');
      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();

      sendAnnouncementMessage(message: 'Hello');
      await waitForNextEventLoop();
      expectMessages(polite: 'Hello');
      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('announce() polite', () async {
      accessibilityAnnouncements.announce('polite message', Assertiveness.polite);
      await waitForNextEventLoop();
      expectMessages(polite: 'polite message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('announce() assertive', () async {
      accessibilityAnnouncements.announce('assertive message', Assertiveness.assertive);
      await waitForNextEventLoop();
      expectMessages(assertive: 'assertive message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('announcement is moved into modal dialog and back', () async {
      final DomElement modalDialog = createDomElement('div');
      modalDialog.setAttribute('aria-modal', 'true');
      domDocument.body!.append(modalDialog);

      final DomHTMLElement politeElement = accessibilityAnnouncements.ariaLiveElementFor(
        Assertiveness.polite,
      );
      final DomElement? originalParent = politeElement.parentElement;
      expect(originalParent, isNotNull);

      accessibilityAnnouncements.announce('modal message', Assertiveness.polite);

      // Element should be moved to modal immediately
      expect(politeElement.parentElement, modalDialog);

      await waitForNextEventLoop();
      expect(politeElement.text, 'modal message');

      await Future<void>.delayed(liveMessageDuration);
      expect(politeElement.text, '');
      expect(politeElement.parentElement, originalParent);

      modalDialog.remove();
    });

    test('announcement works without modal dialog present', () async {
      final DomHTMLElement politeElement = accessibilityAnnouncements.ariaLiveElementFor(
        Assertiveness.polite,
      );
      final DomElement? originalParent = politeElement.parentElement;
      expect(originalParent, isNotNull);

      accessibilityAnnouncements.announce('normal message', Assertiveness.polite);

      expect(politeElement.parentElement, originalParent);

      await waitForNextEventLoop();
      expect(politeElement.text, 'normal message');

      await Future<void>.delayed(liveMessageDuration);
      expect(politeElement.text, '');
      expect(politeElement.parentElement, originalParent);
    });

    test('uses topmost modal dialog when multiple modals exist', () async {
      final DomElement modalDialog1 = createDomElement('div');
      modalDialog1.setAttribute('aria-modal', 'true');
      modalDialog1.id = 'modal1';
      domDocument.body!.append(modalDialog1);

      final DomElement modalDialog2 = createDomElement('div');
      modalDialog2.setAttribute('aria-modal', 'true');
      modalDialog2.id = 'modal2';
      domDocument.body!.append(modalDialog2);

      final DomHTMLElement politeElement = accessibilityAnnouncements.ariaLiveElementFor(
        Assertiveness.polite,
      );

      accessibilityAnnouncements.announce('nested modal message', Assertiveness.polite);

      expect(politeElement.parentElement, modalDialog2);

      await Future<void>.delayed(liveMessageDuration);

      modalDialog1.remove();
      modalDialog2.remove();
    });
  });
}
