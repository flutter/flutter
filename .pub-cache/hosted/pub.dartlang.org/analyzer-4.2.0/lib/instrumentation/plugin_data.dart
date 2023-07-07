// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Information about a plugin.
class PluginData {
  /// The id used to uniquely identify the plugin.
  final String pluginId;

  /// The name of the plugin.
  final String? name;

  /// The version of the plugin.
  final String? version;

  /// Initialize a newly created set of data about a plugin.
  PluginData(this.pluginId, this.name, this.version);

  /// Add the information about the plugin to the list of [fields] to be sent to
  /// the instrumentation server.
  void addToFields(List<String> fields) {
    fields.add(pluginId);
    fields.add(name ?? '');
    fields.add(version ?? '');
  }
}
