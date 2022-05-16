// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

class PubspecContent {
  const PubspecContent(this.content);
  final YamlMap content;

  String? get appName => content['name'] as String?;

  YamlMap get flutterNode => content['flutter'] as YamlMap;

  bool get isFlutterPackage => flutterNode != null;

  bool get usesMaterialDesign {
    if (!isFlutterPackage || !flutterNode.containsKey('uses-material-design')){
      return false;
    }
    return flutterNode['uses-material-design'] as bool;
  }

  bool get isPlugin {
    if (!isFlutterPackage) {
      return false;
    }
    return flutterNode.containsKey('plugin');
  }
}
