// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  input: 'pigeons/messages.dart',
  javaOut:
      'android/src/main/java/io/flutter/plugins/sharedpreferences/Messages.java',
  javaOptions: JavaOptions(
      className: 'Messages', package: 'io.flutter.plugins.sharedpreferences'),
  dartOut: 'lib/src/messages.g.dart',
  copyrightHeader: 'pigeons/copyright.txt',
))
@HostApi(dartHostTestHandler: 'TestSharedPreferencesApi')
abstract class SharedPreferencesApi {
  /// Removes property from shared preferences data set.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool remove(String key);

  /// Adds property to shared preferences data set of type bool.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool setBool(String key, bool value);

  /// Adds property to shared preferences data set of type String.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool setString(String key, String value);

  /// Adds property to shared preferences data set of type int.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool setInt(String key, int value);

  /// Adds property to shared preferences data set of type double.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool setDouble(String key, double value);

  /// Adds property to shared preferences data set of type List<String>.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool setStringList(String key, List<String> value);

  /// Removes all properties from shared preferences data set with matching prefix.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool clearWithPrefix(String prefix);

  /// Gets all properties from shared preferences data set with matching prefix.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Map<String, Object> getAllWithPrefix(String prefix);
}
