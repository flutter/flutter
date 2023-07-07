// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/pigeon/messages.pigeon.dart',
    // We export in the lib folder to expose the class to other packages.
    dartTestOut: 'lib/src/pigeon/test_api.dart',
    javaOut:
        '../firebase_core/android/src/main/java/io/flutter/plugins/firebase/core/GeneratedAndroidFirebaseCore.java',
    javaOptions: JavaOptions(
      package: 'io.flutter.plugins.firebase.core',
      className: 'GeneratedAndroidFirebaseCore',
    ),
    objcHeaderOut: '../firebase_core/ios/Classes/messages.g.h',
    objcSourceOut: '../firebase_core/ios/Classes/messages.g.m',
  ),
)
class PigeonFirebaseOptions {
  PigeonFirebaseOptions({
    required this.authDomain,
    required this.measurementId,
    required this.deepLinkURLScheme,
    required this.androidClientId,
    required this.iosClientId,
    required this.iosBundleId,
    required this.appGroupId,
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.databaseURL,
    required this.storageBucket,
    required this.trackingId,
  });

  final String apiKey;

  final String appId;

  final String messagingSenderId;

  final String projectId;

  final String? authDomain;

  final String? databaseURL;

  final String? storageBucket;

  final String? measurementId;

  final String? trackingId;

  final String? deepLinkURLScheme;

  final String? androidClientId;

  final String? iosClientId;

  final String? iosBundleId;

  final String? appGroupId;
}

class PigeonInitializeResponse {
  PigeonInitializeResponse({
    required this.name,
    required this.options,
    required this.isAutomaticDataCollectionEnabled,
    required this.pluginConstants,
  });

  String name;
  PigeonFirebaseOptions options;
  bool? isAutomaticDataCollectionEnabled;
  Map<String?, Object?> pluginConstants;
}

@HostApi(dartHostTestHandler: 'TestFirebaseCoreHostApi')
abstract class FirebaseCoreHostApi {
  @async
  PigeonInitializeResponse initializeApp(
    String appName,
    PigeonFirebaseOptions initializeAppRequest,
  );

  @async
  List<PigeonInitializeResponse> initializeCore();

  @async
  PigeonFirebaseOptions optionsFromResource();
}

@HostApi(dartHostTestHandler: 'TestFirebaseAppHostApi')
abstract class FirebaseAppHostApi {
  @async
  void setAutomaticDataCollectionEnabled(
    String appName,
    bool enabled,
  );

  @async
  void setAutomaticResourceManagementEnabled(
    String appName,
    bool enabled,
  );

  @async
  void delete(
    String appName,
  );
}
