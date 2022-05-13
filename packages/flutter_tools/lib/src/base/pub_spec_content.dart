// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

class PubContent {
  PubContent(this.content);
  final YamlMap content;

  String? get appName {
    return content['name'] as String?;
  }

  YamlMap get flutterNode {
    return content['flutter'] as YamlMap;
  }

  bool isFlutterPackage() {
    return flutterNode != null;
  }

  bool usesMaterialDesign() {
    if (!isFlutterPackage() || !flutterNode.containsKey('uses-material-design')){
      return false;
    }
    return flutterNode['uses-material-design'] as bool;
  }

  bool isPlugin() {
    if (!isFlutterPackage()) {
      return false;
    }
    return flutterNode.containsKey('plugin');
  }
}
