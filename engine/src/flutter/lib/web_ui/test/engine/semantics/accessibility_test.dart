// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/embedder.dart';
import 'package:ui/src/engine/semantics.dart';
import 'package:ui/src/engine/services.dart';

const StandardMessageCodec codec = StandardMessageCodec();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  late FlutterViewEmbedder embedder;
  late AccessibilityAnnouncements accessibilityAnnouncements;

  setUp(() {
    embedder = FlutterViewEmbedder();
    accessibilityAnnouncements = embedder.accessibilityAnnouncements;
    setLiveMessageDurationForTest(const Duration(milliseconds: 10));
    expect(
      embedder.glassPaneShadow.querySelector('flt-announcement-polite'),
      accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite),
    );
    expect(
      embedder.glassPaneShadow.querySelector('flt-announcement-assertive'),
      accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive),
    );
  });

  tearDown(() async {
    await Future<void>.delayed(liveMessageDuration * 2);
    embedder.glassPaneElement.remove();
  });

  group('$AccessibilityAnnouncements', () {
    ByteData? encodeMessageOnly({required String message}) {
      return codec.encodeMessage(<dynamic, dynamic>{
        'data': <dynamic, dynamic>{'message': message},
      });
    }

    void sendAnnouncementMessage({required String message, int? assertiveness}) {
      accessibilityAnnouncements.handleMessage(codec, codec.encodeMessage(<dynamic, dynamic>{
        'data': <dynamic, dynamic>{
          'message': message,
          'assertiveness': assertiveness,
        },
      }));
    }

    void expectMessages({String polite = '', String assertive = ''}) {
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.polite).text, polite);
      expect(accessibilityAnnouncements.ariaLiveElementFor(Assertiveness.assertive).text, assertive);
    }

    void expectNoMessages() => expectMessages();

    test('Default value of aria-live is polite when assertiveness is not specified', () async {
      accessibilityAnnouncements.handleMessage(codec, encodeMessageOnly(message: 'polite message'));
      expectMessages(polite: 'polite message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('aria-live is assertive when assertiveness is set to 1', () async {
      sendAnnouncementMessage(message: 'assertive message', assertiveness: 1);
      expectMessages(assertive: 'assertive message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('aria-live is polite when assertiveness is null', () async {
      sendAnnouncementMessage(message: 'polite message');
      expectMessages(polite: 'polite message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('aria-live is polite when assertiveness is set to 0', () async {
      sendAnnouncementMessage(message: 'polite message', assertiveness: 0);
      expectMessages(polite: 'polite message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('Rapid-fire messages are each announced.', () async {
      sendAnnouncementMessage(message: 'Hello');
      expectMessages(polite: 'Hello');

      await Future<void>.delayed(liveMessageDuration * 0.5);
      sendAnnouncementMessage(message: 'There');
      expectMessages(polite: 'HelloThere');

      await Future<void>.delayed(liveMessageDuration * 0.6);
      expectMessages(polite: 'There');

      await Future<void>.delayed(liveMessageDuration * 0.5);
      expectNoMessages();
    });

    test('announce() polite', () async {
      accessibilityAnnouncements.announce('polite message', Assertiveness.polite);
      expectMessages(polite: 'polite message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });

    test('announce() assertive', () async {
      accessibilityAnnouncements.announce('assertive message', Assertiveness.assertive);
      expectMessages(assertive: 'assertive message');

      await Future<void>.delayed(liveMessageDuration);
      expectNoMessages();
    });
  });
}
