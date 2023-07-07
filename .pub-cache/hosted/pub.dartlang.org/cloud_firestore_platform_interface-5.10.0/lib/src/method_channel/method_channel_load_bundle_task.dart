// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas
import 'dart:async';
// TODO(Lyokone): remove once we bump Flutter SDK min version to 3.3
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'method_channel_firestore.dart';

class MethodChannelLoadBundleTask extends LoadBundleTaskPlatform {
  MethodChannelLoadBundleTask({
    required Future<String?> task,
    required Uint8List bundle,
    required MethodChannelFirebaseFirestore firestore,
  }) : super() {
    Stream<LoadBundleTaskSnapshotPlatform> mapNativeStream() async* {
      final observerId = await task;

      final nativePlatformStream =
          MethodChannelFirebaseFirestore.loadBundleChannel(observerId!)
              .receiveBroadcastStream(
        <String, Object>{'bundle': bundle, 'firestore': firestore},
      );
      try {
        await for (final snapshot in nativePlatformStream) {
          final taskState = convertToTaskState(snapshot['taskState']);

          yield LoadBundleTaskSnapshotPlatform(
              taskState, Map<String, dynamic>.from(snapshot));

          if (taskState == LoadBundleTaskState.success) {
            // this will close the stream and stop listening to nativePlatformStream
            return;
          }
        }
      } catch (exception) {
        // TODO this should be refactored to use `convertPlatformException`,
        // then change receiveBroadcastStream -> receiveGuardedBroadedStream
        if (exception is! Exception || exception is! PlatformException) {
          rethrow;
        }

        Map<String, String>? details = exception.details != null
            ? Map<String, String>.from(exception.details)
            : null;

        throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'load-bundle-error',
            message: details?['message'] ?? '');
      }
    }

    stream = mapNativeStream().asBroadcastStream(
        onListen: (sub) => sub.resume(), onCancel: (sub) => sub.pause());
  }

  @override
  late final Stream<LoadBundleTaskSnapshotPlatform> stream;
}
