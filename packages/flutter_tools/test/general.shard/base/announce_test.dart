// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/announce.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/testbed.dart';

void main() {
  group('Announce', () {
    Testbed testbed;
    MockBotDetector mockBotDetector;
    MockConfig mockConfig;

    setUp(() {
      mockConfig = MockConfig();
      mockBotDetector = MockBotDetector();
      when(mockBotDetector.isRunningOnBot).thenReturn(false);
      when<bool>(mockConfig.getValue(kFlutterAnnounceConfig)).thenReturn(false);
      testbed = Testbed(
        overrides: <Type, Generator>{
          BotDetector: () => mockBotDetector,
          Config: () => mockConfig,
        }
      );
    });

    test('can be deserialized from json', () {
      const String source = '{"id":"2","message":"hello","link":"abc"}';
      final Announcement announcement = Announcement.fromJson(json.decode(source));

      expect(announcement.id, '2');
      expect(announcement.message, 'hello');
      expect(announcement.link, 'abc');
    });

    test('default service implementation', () {
      const AnnouncementService announcementService = AnnouncementService();

      expect(announcementService.announcementsEnabled, false);
      expect(announcementService.fetchLatestAnnouncement(), null);
    });

    test('returns null if network returns 400', () => testbed.run(() async {
      const FlutterAnnouncementService announcementService = FlutterAnnouncementService();

      expect(await announcementService.fetchLatestAnnouncement(), null);
    }));

    test('is not enabled if on a bot', () => testbed.run(() async {
      when(mockBotDetector.isRunningOnBot).thenReturn(true);

      expect(const FlutterAnnouncementService().announcementsEnabled, false);
    }));

    test('is not enabled if muted', () => testbed.run(() async {
      when<bool>(mockConfig.getValue(kFlutterAnnounceConfig)).thenReturn(true);

      expect(const FlutterAnnouncementService().announcementsEnabled, false);
    }));

    test('is otherwise enabled', () => testbed.run(() async {
      when<bool>(mockConfig.getValue(kFlutterAnnounceConfig)).thenReturn(false);

      expect(const FlutterAnnouncementService().announcementsEnabled, true);
    }));
  });
}

class MockBotDetector extends Mock implements BotDetector {}
class MockConfig extends Mock implements Config {}
