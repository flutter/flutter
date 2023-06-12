// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/messages.g.dart',
  dartTestOut: 'test/messages.g.dart',
  objcHeaderOut: 'ios/Classes/messages.g.h',
  objcSourceOut: 'ios/Classes/messages.g.m',
  copyrightHeader: 'pigeons/copyright_header.txt',
))
@HostApi(dartHostTestHandler: 'TestUserDefaultsApi')
abstract class UserDefaultsApi {
  void remove(String key);
  void setBool(String key, bool value);
  void setDouble(String key, double value);
  void setValue(String key, Object value);
  Map<String?, Object?> getAll();
  void clear();
}
