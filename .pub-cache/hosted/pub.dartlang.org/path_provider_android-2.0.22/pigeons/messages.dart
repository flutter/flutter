// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  input: 'pigeons/messages.dart',
  javaOut:
      'android/src/main/java/io/flutter/plugins/pathprovider/Messages.java',
  javaOptions: JavaOptions(
      className: 'Messages', package: 'io.flutter.plugins.pathprovider'),
  dartOut: 'lib/messages.g.dart',
  dartTestOut: 'test/messages_test.g.dart',
  copyrightHeader: 'pigeons/copyright.txt',
))
enum StorageDirectory {
  root,
  music,
  podcasts,
  ringtones,
  alarms,
  notifications,
  pictures,
  movies,
  downloads,
  dcim,
  documents,
}

@HostApi(dartHostTestHandler: 'TestPathProviderApi')
abstract class PathProviderApi {
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  String? getTemporaryPath();
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  String? getApplicationSupportPath();
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  String? getApplicationDocumentsPath();
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  String? getExternalStoragePath();
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<String?> getExternalCachePaths();
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  List<String?> getExternalStoragePaths(StorageDirectory directory);
}
