// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic_project.dart';
import 'deferred_components_config.dart';
import 'deferred_components_project.dart';

class PluginProject extends BasicProject {
  @override
  final DeferredComponentsConfig? deferredComponents =
      BasicDeferredComponentsConfig();
}
