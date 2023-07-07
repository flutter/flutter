// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  input: 'pigeons/messages.dart',
  objcOptions: ObjcOptions(prefix: 'FLT'),
  objcHeaderOut: 'ios/Classes/messages.g.h',
  objcSourceOut: 'ios/Classes/messages.g.m',
  dartOut: 'lib/messages.g.dart',
  dartTestOut: 'test/messages_test.g.dart',
  copyrightHeader: 'pigeons/copyright.txt',
))
@HostApi(dartHostTestHandler: 'TestPathProviderApi')
abstract class PathProviderApi {
  String? getTemporaryPath();
  String? getApplicationSupportPath();
  String? getLibraryPath();
  String? getApplicationDocumentsPath();
}
