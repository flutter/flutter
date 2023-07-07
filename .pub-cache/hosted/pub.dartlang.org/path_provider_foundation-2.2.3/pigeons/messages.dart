// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  input: 'pigeons/messages.dart',
  swiftOut: 'macos/Classes/messages.g.swift',
  dartOut: 'lib/messages.g.dart',
  dartTestOut: 'test/messages_test.g.dart',
  copyrightHeader: 'pigeons/copyright.txt',
))
enum DirectoryType {
  applicationDocuments,
  applicationSupport,
  downloads,
  library,
  temp,
}

@HostApi(dartHostTestHandler: 'TestPathProviderApi')
abstract class PathProviderApi {
  String? getDirectoryPath(DirectoryType type);
  String? getContainerPath(String appGroupIdentifier);
}
