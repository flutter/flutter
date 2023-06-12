// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/messages.g.dart',
  dartTestOut: 'test/test_api.g.dart',
  swiftOut: 'macos/Classes/messages.g.swift',
  copyrightHeader: 'pigeons/copyright_header.txt',
))
@HostApi(dartHostTestHandler: 'TestUserDefaultsApi')
abstract class UserDefaultsApi {
  void remove(String key);
  // TODO(stuartmorgan): Give these setters better Swift signatures (_,forKey:)
  // once https://github.com/flutter/flutter/issues/105932 is fixed.
  void setBool(String key, bool value);
  void setDouble(String key, double value);
  void setValue(String key, Object value);
  // TODO(stuartmorgan): Make these non-nullable once
  // https://github.com/flutter/flutter/issues/97848 is fixed.
  Map<String?, Object?> getAll();
  void clear();
}
