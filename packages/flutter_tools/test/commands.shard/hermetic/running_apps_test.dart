// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/commands/running_apps.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  testUsingContext('running-apps command returns success', () async {
    final fakeMDnsClient = FakeMDnsClient(
      <PtrResourceRecord>[],
      <String, List<SrvResourceRecord>>{},
      <String, List<TxtResourceRecord>>{},
    );
    final command = RunningAppsCommand(
      mdnsClient: fakeMDnsClient,
      logger: testLogger,
      systemClock: SystemClock.fixed(DateTime(2015)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['running-apps']);
  });

  testUsingContext('running-apps finds no apps', () async {
    final fakeMDnsClient = FakeMDnsClient(
      <PtrResourceRecord>[],
      <String, List<SrvResourceRecord>>{},
      <String, List<TxtResourceRecord>>{},
    );
    final command = RunningAppsCommand(
      mdnsClient: fakeMDnsClient,
      logger: testLogger,
      systemClock: SystemClock.fixed(DateTime(2015)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['running-apps']);

    expect(
      testLogger.statusText,
      contains(
        'No running Flutter apps found.\n'
        'Note: Flutter running-apps only detects apps running with the '
        '"--enable-local-discovery" flag (debug/profile mode only).',
      ),
    );
  });

  testUsingContext('running-apps finds one app', () async {
    final fakeMDnsClient = FakeMDnsClient(
      <PtrResourceRecord>[const PtrResourceRecord('foo', 100, domainName: 'service.local')],
      <String, List<SrvResourceRecord>>{
        'service.local': <SrvResourceRecord>[
          const SrvResourceRecord(
            'service.local',
            100,
            port: 1234,
            weight: 0,
            priority: 0,
            target: 'target.local',
          ),
        ],
      },
      <String, List<TxtResourceRecord>>{
        'service.local': <TxtResourceRecord>[
          const TxtResourceRecord(
            'service.local',
            100,
            text: '''
project_name=my_project
device_name=macos
device_id=macos
target_platform=darwin-arm64
mode=debug
ws_uri=ws://127.0.0.1:1234/ws
epoch=1000
pid=123
hostname=localhost
flutter_version=1.0.0
dart_version=2.0.0''',
          ),
        ],
      },
    );
    final command = RunningAppsCommand(
      mdnsClient: fakeMDnsClient,
      logger: testLogger,
      systemClock: SystemClock.fixed(DateTime(2015)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['running-apps']);

    expect(testLogger.statusText, contains('Found 1 running Flutter app:'));
    expect(
      testLogger.statusText,
      contains('my_project (debug) • macos • darwin-arm64 • ws://127.0.0.1:1234/ws'),
    );
  });

  testUsingContext('running-apps finds multiple apps with formatting', () async {
    final fakeMDnsClient = FakeMDnsClient(
      <PtrResourceRecord>[
        const PtrResourceRecord('bar', 100, domainName: 'service2.local'),
        const PtrResourceRecord('foo', 100, domainName: 'service1.local'),
      ],
      <String, List<SrvResourceRecord>>{
        'service1.local': <SrvResourceRecord>[
          const SrvResourceRecord(
            'service1.local',
            100,
            port: 1234,
            weight: 0,
            priority: 0,
            target: 'target1.local',
          ),
        ],
        'service2.local': <SrvResourceRecord>[
          const SrvResourceRecord(
            'service2.local',
            100,
            port: 5678,
            weight: 0,
            priority: 0,
            target: 'target2.local',
          ),
        ],
      },
      <String, List<TxtResourceRecord>>{
        'service1.local': <TxtResourceRecord>[
          const TxtResourceRecord(
            'service1.local',
            100,
            text: '''
project_name=app_one
device_name=macos
device_id=macos
target_platform=darwin-arm64
mode=debug
ws_uri=ws://127.0.0.1:1234/ws
epoch=1000
pid=1001
hostname=host1
flutter_version=1.0.0
dart_version=2.0.0''',
          ),
        ],
        'service2.local': <TxtResourceRecord>[
          const TxtResourceRecord(
            'service2.local',
            100,
            text: '''
project_name=app_two
device_name=chrome
device_id=chrome
target_platform=web-javascript
mode=release
ws_uri=ws://127.0.0.1:5678/ws
epoch=0
pid=1002
hostname=host2
flutter_version=1.0.0
dart_version=2.0.0''',
          ),
        ],
      },
    );
    final command = RunningAppsCommand(
      mdnsClient: fakeMDnsClient,
      logger: testLogger,
      systemClock: SystemClock.fixed(DateTime.fromMillisecondsSinceEpoch(2000)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['running-apps']);

    expect(testLogger.statusText, contains('Found 2 running Flutter apps:'));

    // Verify sorting: app_one (1s, younger) should come before app_two (2s, older).
    final int index1 = testLogger.statusText.indexOf('app_one');
    final int index2 = testLogger.statusText.indexOf('app_two');
    expect(
      index1,
      lessThan(index2),
      reason: 'app_one (younger) should be listed before app_two (older)',
    );

    // Verify formatting - 2 spaces indent, bullet separator
    expect(
      testLogger.statusText,
      contains('  app_one (debug)   • macos  • darwin-arm64   • ws://127.0.0.1:1234/ws • 1s'),
    );
    expect(
      testLogger.statusText,
      contains('  app_two (release) • chrome • web-javascript • ws://127.0.0.1:5678/ws • 2s'),
    );
  });

  testUsingContext('running-apps deduplicates apps with same ws_uri', () async {
    final fakeMDnsClient = FakeMDnsClient(
      <PtrResourceRecord>[
        const PtrResourceRecord('foo', 100, domainName: 'service.local'),
        const PtrResourceRecord('bar', 100, domainName: 'service_dup.local'),
      ],
      <String, List<SrvResourceRecord>>{
        'service.local': <SrvResourceRecord>[
          const SrvResourceRecord(
            'service.local',
            100,
            port: 1234,
            weight: 0,
            priority: 0,
            target: 'target.local',
          ),
        ],
        'service_dup.local': <SrvResourceRecord>[
          const SrvResourceRecord(
            'service_dup.local',
            100,
            port: 1234,
            weight: 0,
            priority: 0,
            target: 'target.local',
          ),
        ],
      },
      <String, List<TxtResourceRecord>>{
        'service.local': <TxtResourceRecord>[
          const TxtResourceRecord(
            'service.local',
            100,
            text: '''
project_name=app_one
ws_uri=ws://127.0.0.1:1234/ws
epoch=1000
pid=2001
hostname=host_dup
device_name=dev
device_id=dev_id
target_platform=ios
mode=debug
flutter_version=1.0.0
dart_version=2.0.0''',
          ),
        ],
        'service_dup.local': <TxtResourceRecord>[
          // Same URI as above
          const TxtResourceRecord(
            'service_dup.local',
            100,
            text: '''
project_name=app_one
ws_uri=ws://127.0.0.1:1234/ws
epoch=1000
pid=2001
hostname=host_dup
device_name=dev
device_id=dev_id
target_platform=ios
mode=debug
flutter_version=1.0.0
dart_version=2.0.0''',
          ),
        ],
      },
    );
    final command = RunningAppsCommand(
      mdnsClient: fakeMDnsClient,
      logger: testLogger,
      systemClock: SystemClock.fixed(DateTime.fromMillisecondsSinceEpoch(2000)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['running-apps']);

    expect(testLogger.statusText, contains('Found 1 running Flutter app:'));
    expect('app_one'.allMatches(testLogger.statusText), hasLength(1));
  });

  testUsingContext('running-apps handles whitespace in TXT records', () async {
    final fakeMDnsClient = FakeMDnsClient(
      <PtrResourceRecord>[const PtrResourceRecord('foo', 100, domainName: 'service.local')],
      <String, List<SrvResourceRecord>>{
        'service.local': <SrvResourceRecord>[
          const SrvResourceRecord(
            'service.local',
            100,
            port: 1234,
            weight: 0,
            priority: 0,
            target: 'target.local',
          ),
        ],
      },
      <String, List<TxtResourceRecord>>{
        'service.local': <TxtResourceRecord>[
          const TxtResourceRecord(
            'service.local',
            100,
            text: '''
 project_name = app_one
 ws_uri = ws://127.0.0.1:1234/ws
 epoch = 1000
 pid = 3001
 hostname = host_white
 device_name = dev
 device_id = dev_id
 target_platform = android
 mode = debug
 flutter_version = 1.0.0
 dart_version = 2.0.0 ''',
          ),
        ],
      },
    );
    final command = RunningAppsCommand(
      mdnsClient: fakeMDnsClient,
      logger: testLogger,
      systemClock: SystemClock.fixed(DateTime.fromMillisecondsSinceEpoch(2000)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(command);
    await runner.run(<String>['running-apps']);

    expect(testLogger.statusText, contains('Found 1 running Flutter app:'));
    expect('app_one'.allMatches(testLogger.statusText), hasLength(1));
    expect(testLogger.statusText, contains('ws://127.0.0.1:1234/ws'));
  });

  testWithoutContext('processAge', () {
    const kSecondMs = 1000;
    const int kMinuteMs = kSecondMs * 60;
    const int kHourMs = kMinuteMs * 60;
    const int kDayMs = kHourMs * 24;

    const kNowMs = 10_000_000;
    const int kFiveSecondsMs = 5 * kSecondMs;
    const int kFiftyNineSecondsMs = 59 * kSecondMs;
    const int kFiftyNineMinutesMs = 59 * kMinuteMs;
    const int kTwentyThreeHoursMs = 23 * kHourMs;
    const int kTwoDaysMs = 2 * kDayMs;

    final now = DateTime.fromMillisecondsSinceEpoch(kNowMs);
    final clock = SystemClock.fixed(now);

    expect(processAge(null, clock), 'unknown age');

    // Seconds
    expect(processAge(kNowMs - kFiveSecondsMs, clock), '5s');
    expect(processAge(kNowMs - kFiftyNineSecondsMs, clock), '59s');

    // Minutes
    expect(processAge(kNowMs - kMinuteMs, clock), '1m');
    expect(processAge(kNowMs - kFiftyNineMinutesMs, clock), '59m');

    // Hours
    expect(processAge(kNowMs - kHourMs, clock), '1h');
    expect(processAge(kNowMs - kTwentyThreeHoursMs, clock), '23h');

    // Days
    expect(processAge(kNowMs - kDayMs, clock), '1d');
    expect(processAge(kNowMs - kTwoDaysMs, clock), '2d');
  });
}

class FakeMDnsClient extends Fake implements MDnsClient {
  FakeMDnsClient(this.ptrRecords, this.srvRecords, this.txtRecords);

  final List<PtrResourceRecord> ptrRecords;
  final Map<String, List<SrvResourceRecord>> srvRecords;
  final Map<String, List<TxtResourceRecord>> txtRecords;

  @override
  Future<void> start({
    InternetAddress? listenAddress,
    NetworkInterfacesFactory? interfacesFactory,
    int mDnsPort = 5353,
    InternetAddress? mDnsAddress,
    Function? onError,
  }) async {}

  @override
  void stop() {}

  @override
  Stream<T> lookup<T extends ResourceRecord>(
    ResourceRecordQuery query, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    if (T == PtrResourceRecord) {
      return Stream<T>.fromIterable(ptrRecords as List<T>);
    }
    if (T == SrvResourceRecord) {
      // The query name for SRV records is the domain name (which is query.fullyQualifiedName or specific field depending on usages).
      // MDnsClient.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName)) uses the name as the fully qualified domain name.
      // ResourceRecordQuery implementation details:
      // In multicast_dns, ResourceRecordQuery has a `fullyQualifiedName` property.
      // When calling ResourceRecordQuery.service(name), it sets the fullyQualifiedName.
      return Stream<T>.fromIterable(
        (srvRecords[query.fullyQualifiedName] ?? <SrvResourceRecord>[]) as List<T>,
      );
    }
    if (T == TxtResourceRecord) {
      return Stream<T>.fromIterable(
        (txtRecords[query.fullyQualifiedName] ?? <TxtResourceRecord>[]) as List<T>,
      );
    }
    return const Stream<Never>.empty();
  }
}
