// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

Future<developer.ServiceExtensionResponse> _reinitializeScene(
  String method,
  Map<String, String> parameters,
) async {
  final String? assetKey = parameters['assetKey'];
  if (assetKey != null) {
    await SceneNode._reinitializeScene(assetKey);
  }

  // Always succeed.
  return developer.ServiceExtensionResponse.result(json.encode(<String, String>{
    'type': 'Success',
  }));
}

// This is a copy of ui/setup_hooks.dart, but with reinitializeScene added for hot reloading 3D scenes.

@pragma('vm:entry-point')
void _setupHooks() {
  assert(() {
    // In debug mode, register the schedule frame extension.
    developer.registerExtension('ext.ui.window.scheduleFrame', _scheduleFrame);

    // In debug mode, allow shaders to be reinitialized.
    developer.registerExtension(
      'ext.ui.window.reinitializeShader',
      _reinitializeShader,
    );

    // In debug mode, allow 3D scenes to be reinitialized.
    developer.registerExtension(
      'ext.ui.window.reinitializeScene',
      _reinitializeScene,
    );
    return true;
  }());

  // In debug and profile mode, allow tools to display the current rendering backend.
  if (!_kReleaseMode) {
    developer.registerExtension(
      'ext.ui.window.impellerEnabled',
      _getImpellerEnabled,
    );
  }
}
