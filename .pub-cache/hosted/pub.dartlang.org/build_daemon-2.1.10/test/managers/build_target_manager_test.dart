// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build_daemon/data/build_target.dart';
import 'package:build_daemon/src/managers/build_target_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  test('can add build targets', () {
    var manager = BuildTargetManager();
    var channel = DummyChannel();
    var target = DefaultBuildTarget((b) => b..target = 'foo');
    expect(manager.targets.isEmpty, isTrue);
    manager.addBuildTarget(target, channel);
    expect(manager.targets.map((target) => target.target), contains('foo'));
  });

  test('returns an empty set when no channels are interested', () {
    var manager = BuildTargetManager();
    var target = DefaultBuildTarget((b) => b..target = 'foo');
    var targetB = DefaultBuildTarget((b) => b..target = 'bar');
    var channel = DummyChannel();
    manager.addBuildTarget(target, channel);
    expect(manager.channels(targetB), isEmpty);
  });

  test('can return all connected channels', () {
    var manager = BuildTargetManager();
    var target = DefaultBuildTarget((b) => b..target = 'foo');
    var targetB = DefaultBuildTarget((b) => b..target = 'bar');
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    manager
      ..addBuildTarget(target, channelA)
      ..addBuildTarget(targetB, channelB);
    expect(manager.allChannels, containsAll([channelA, channelB]));
    expect(manager.allChannels.length, 2);

    manager.removeChannel(channelA);

    expect(manager.allChannels, contains(channelB));
    expect(manager.allChannels.length, 1);
  });

  test('when a channel is removed the corresponding target is removed', () {
    var manager = BuildTargetManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    var targetA = DefaultBuildTarget((b) => b..target = 'foo');
    manager.addBuildTarget(targetA, channelA);
    expect(manager.targets.map((target) => target.target), contains('foo'));
    var targetB = DefaultBuildTarget((b) => b..target = 'bar');
    manager.addBuildTarget(targetB, channelB);
    expect(manager.targets.isNotEmpty, isTrue);
    manager.removeChannel(channelA);
    expect(manager.targets.map((target) => target.target).toList(),
        allOf(isNot(contains('foo')), contains('bar')));
  });

  test(
      'when multiple channels are listening to a target, '
      'it is only removed when both channels are removed', () {
    var manager = BuildTargetManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    var target = DefaultBuildTarget((b) => b..target = 'foo');
    manager..addBuildTarget(target, channelA)..addBuildTarget(target, channelB);
    expect(manager.targets.map((target) => target.target), contains('foo'));
    manager.removeChannel(channelB);
    expect(manager.targets.map((target) => target.target), contains('foo'));
    manager.removeChannel(channelA);
    expect(manager.targets.isEmpty, isTrue);
  });

  test(
      'a build target will be reused if the target and the blackListPattern '
      'is the same', () {
    var manager = BuildTargetManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    var targetA = DefaultBuildTarget((b) => b
      ..target = 'foo'
      ..blackListPatterns.replace([RegExp('bar')]));
    var targetB = DefaultBuildTarget((b) => b
      ..target = 'foo'
      ..blackListPatterns.replace([RegExp('bar')]));
    manager
      ..addBuildTarget(targetA, channelA)
      ..addBuildTarget(targetB, channelB);
    expect(manager.targets.length, 1);
  });

  test('different blackListPatterns result in different build targets', () {
    var manager = BuildTargetManager();
    var channelA = DummyChannel();
    var channelB = DummyChannel();
    var targetA = DefaultBuildTarget((b) => b..target = 'foo');
    var targetB = DefaultBuildTarget((b) => b
      ..target = 'foo'
      ..blackListPatterns.replace([RegExp('bar')]));
    manager
      ..addBuildTarget(targetA, channelA)
      ..addBuildTarget(targetB, channelB);
    expect(manager.targets.length, 2);
  });

  test(
      'correctly uses the blackListPattern to filter build targets for changes',
      () {
    var manager = BuildTargetManager();
    var channel = DummyChannel();
    var target = DefaultBuildTarget((b) => b
      ..target = 'foo'
      ..blackListPatterns.replace([RegExp(r'.*_test\.dart$')]));
    manager.addBuildTarget(target, channel);
    var targets = manager.targetsForChanges(
        [WatchEvent(ChangeType.ADD, 'foo/bar/blah/some_file.dart')]);
    expect(targets.map((target) => target.target), contains('foo'));
    targets = manager.targetsForChanges(
        [WatchEvent(ChangeType.ADD, 'foo/bar/blah/some_test.dart')]);
    expect(targets.isEmpty, isTrue);
  });
}

class DummyChannel extends Mock implements WebSocketChannel {}
