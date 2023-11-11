// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'deferred_components_config.dart';
import 'plugin_project.dart';

class PluginEachSettingsGradleProject extends PluginProject {
  @override
  DeferredComponentsConfig get deferredComponents =>
      PluginEachSettingsGradleDeferredComponentsConfig();
}

class PluginEachSettingsGradleDeferredComponentsConfig
    extends PluginDeferredComponentsConfig {
  @override
  String get androidSettings => r'''
include ':app'
def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()
def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
}
plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":$name"
    project(":$name").projectDir = pluginDirectory
}
  ''';
}
