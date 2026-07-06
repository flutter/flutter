// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';

import 'build.dart';

/// Helper to recreate the plugin symlinks directory and link each resolved plugin
/// specifically for tool extension platforms.
///
/// Unlike standard host-side plugin symlinking which assumes specific directories
/// and CMake project layouts, this utility creates symlinks from the actual plugin
/// directory on the host to the target directory requested by the custom platform.
/// This allows custom extension platforms to manage their own native dependencies.
void createExtensionPluginSymlinks({
  required FileSystem fileSystem,
  required List<ExtensionPlugin> plugins,
  required Directory symlinkDirectory,
  bool force = false,
}) {
  if (force) {
    if (symlinkDirectory.existsSync()) {
      try {
        symlinkDirectory.deleteSync(recursive: true);
      } on FileSystemException {
        // Ignore if delete fails.
      }
    }
  }
  symlinkDirectory.createSync(recursive: true);

  for (final plugin in plugins) {
    final Link link = symlinkDirectory.childLink(plugin.name);
    if (!link.existsSync()) {
      try {
        link.createSync(plugin.path);
      } on FileSystemException catch (e) {
        throw Exception('Failed to create plugin symlink from ${plugin.path} to ${link.path}: $e');
      }
    }
  }
}

/// Generates the content of `generated_plugins.cmake` for CMake-based extension platforms.
///
/// This parses the custom configuration of each [ExtensionPlugin] to separate FFI-based plugins
/// from standard MethodChannel-based plugins. FFI-based plugins do not require a companion
/// C++ class but still need to be linked and bundled.
/// FFI-based plugins are identified by the 'ffiPlugin' flag in their configuration,
/// whereas MethodChannel plugins must specify a 'class' property representing the C++ plugin class.
String generateCmakePluginsFile({
  required String os,
  required List<ExtensionPlugin> plugins,
  required String pluginsDir,
}) {
  final List<ExtensionPlugin> methodChannelPlugins = plugins.where((ExtensionPlugin p) {
    return p.configuration['class'] != null;
  }).toList();

  final List<ExtensionPlugin> ffiPlugins = plugins.where((ExtensionPlugin p) {
    return p.configuration['ffiPlugin'] == true && p.configuration['class'] == null;
  }).toList();

  final cmakeContent = StringBuffer();
  cmakeContent.writeln('#');
  cmakeContent.writeln('# Generated file, do not edit.');
  cmakeContent.writeln('#');
  cmakeContent.writeln();
  cmakeContent.writeln('list(APPEND FLUTTER_PLUGIN_LIST');
  for (final plugin in methodChannelPlugins) {
    cmakeContent.writeln('  ${plugin.name}');
  }
  cmakeContent.writeln(')');
  cmakeContent.writeln();
  cmakeContent.writeln('list(APPEND FLUTTER_FFI_PLUGIN_LIST');
  for (final plugin in ffiPlugins) {
    cmakeContent.writeln('  ${plugin.name}');
  }
  cmakeContent.writeln(')');
  cmakeContent.writeln();
  cmakeContent.writeln('set(PLUGIN_BUNDLED_LIBRARIES)');
  cmakeContent.writeln();
  cmakeContent.writeln(r'foreach(plugin ${FLUTTER_PLUGIN_LIST})');
  cmakeContent.writeln('  add_subdirectory($pluginsDir/\${plugin}/$os plugins/\${plugin})');
  cmakeContent.writeln(r'  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)');
  cmakeContent.writeln(r'  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)');
  cmakeContent.writeln(r'  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})');
  cmakeContent.writeln(r'endforeach(plugin)');
  cmakeContent.writeln();
  cmakeContent.writeln(r'foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})');
  cmakeContent.writeln('  add_subdirectory($pluginsDir/\${ffi_plugin}/$os plugins/\${ffi_plugin})');
  cmakeContent.writeln(
    r'  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})',
  );
  cmakeContent.writeln(r'endforeach(ffi_plugin)');
  return cmakeContent.toString();
}
