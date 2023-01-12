// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
part of dart.ui;

/// A composable [SceneNode].
class SceneNode extends NativeFieldWrapperClass1 {
  @pragma('vm:entry-point')
  SceneNode._create() {
    _constructor();
  }

  String? _debugName;

  /// Creates a scene node from the asset with key [assetKey].
  ///
  /// The asset must be a file produced as the output of the `scenec` importer.
  /// The constructed object should then be reused via the [shader]
  /// method to create [Shader] objects that can be used by [Shader.paint].
  static Future<SceneNode> fromAsset(String assetKey) {
    // The flutter tool converts all asset keys with spaces into URI
    // encoded paths (replacing ' ' with '%20', for example). We perform
    // the same encoding here so that users can load assets with the same
    // key they have written in the pubspec.
    final String encodedKey = Uri(path: Uri.encodeFull(assetKey)).path;
    {
      final Future<SceneNode>? futureSceneNode = _ipsceneRegistry[encodedKey]?.target;
      if (futureSceneNode != null) {
        return futureSceneNode;
      }
    }

    final SceneNode sceneNode = SceneNode._create();

    final Future<SceneNode> futureSceneNode = _futurize((_Callback<void> callback) {
      final String error = sceneNode._initFromAsset(assetKey, callback);
      if (error.isNotEmpty) {
        return error;
      }
      assert(() {
        sceneNode._debugName = assetKey;
        return true;
      }());

      return null;
    }).then((_) => sceneNode);

    _ipsceneRegistry[encodedKey] = WeakReference<Future<SceneNode>>(futureSceneNode);
    return futureSceneNode;
  }

  static SceneNode fromTransform(Float64List matrix4) {
    final SceneNode sceneNode = SceneNode._create();
    sceneNode._initFromTransform(matrix4);
    return sceneNode;
  }

  void addChild(SceneNode sceneNode) {
    _addChild(sceneNode);
  }

  void setTransform(Float64List matrix4) {
    _setTransform(matrix4);
  }

  void setAnimationState(String animationName, bool playing, bool loop, double weight, double timeScale) {
    _setAnimationState(animationName, playing, loop, weight, timeScale);
  }

  void seekAnimation(String animationName, double time) {
    _seekAnimation(animationName, time);
  }

  // This is a cache of ipscene-backed scene nodes that have been loaded via
  // SceneNode.fromAsset. It holds weak references to the SceneNodes so that the
  // case where an in-use ipscene is requested again can be fast, but scenes
  // that are no longer referenced are not retained because of the cache.
  static final Map<String, WeakReference<Future<SceneNode>>> _ipsceneRegistry =
      <String, WeakReference<Future<SceneNode>>>{};

  static Future<void> _reinitializeScene(String assetKey) async {
    final WeakReference<Future<SceneNode>>? sceneRef = _ipsceneRegistry == null
      ? null
      : _ipsceneRegistry[assetKey];

    // If a scene for the asset isn't already registered, then there's no
    // need to reinitialize it.
    if (sceneRef == null) {
      return;
    }

    final Future<SceneNode>? sceneNodeFuture = sceneRef.target;
    if (sceneNodeFuture == null) {
      return;
    }
    final SceneNode sceneNode = await sceneNodeFuture;

    await _futurize((_Callback<void> callback) {
      final String error = sceneNode._initFromAsset(assetKey, callback);
      if (error.isNotEmpty) {
        return error;
      }
      return null;
    });
  }

  @FfiNative<Void Function(Handle)>('SceneNode::Create')
  external void _constructor();

  @FfiNative<Handle Function(Pointer<Void>, Handle, Handle)>('SceneNode::initFromAsset')
  external String _initFromAsset(String assetKey, _Callback<void> completionCallback);

  @FfiNative<Void Function(Pointer<Void>, Handle)>('SceneNode::initFromTransform')
  external void _initFromTransform(Float64List matrix4);

  @FfiNative<Void Function(Pointer<Void>, Handle)>('SceneNode::AddChild')
  external void _addChild(SceneNode sceneNode);

  @FfiNative<Void Function(Pointer<Void>, Handle)>('SceneNode::SetTransform')
  external void _setTransform(Float64List matrix4);

  @FfiNative<Void Function(Pointer<Void>, Handle, Bool, Bool, Double, Double)>('SceneNode::SetAnimationState')
  external void _setAnimationState(String animationName, bool playing, bool loop, double weight, double timeScale);

  @FfiNative<Void Function(Pointer<Void>, Handle, Double)>('SceneNode::SeekAnimation')
  external void _seekAnimation(String animationName, double time);

  /// Returns a fresh instance of [SceneShader].
  SceneShader sceneShader() => SceneShader._(this, debugName: _debugName);
}

/// A [Shader] generated from a [SceneNode].
///
/// Instances of this class can be obtained from the
/// [SceneNode.sceneShader] method.
class SceneShader extends Shader {
  SceneShader._(SceneNode node, { String? debugName }) : _debugName = debugName, super._() {
    _constructor(node);
  }

  // ignore: unused_field
  final String? _debugName;

  void setCameraTransform(Float64List matrix4) {
    _setCameraTransform(matrix4);
  }

  /// Releases the native resources held by the [SceneShader].
  ///
  /// After this method is called, calling methods on the shader, or attaching
  /// it to a [Paint] object will fail with an exception. Calling [dispose]
  /// twice will also result in an exception being thrown.
  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  @FfiNative<Void Function(Handle, Handle)>('SceneShader::Create')
  external void _constructor(SceneNode node);

  @FfiNative<Void Function(Pointer<Void>, Handle)>('SceneShader::SetCameraTransform')
  external void _setCameraTransform(Float64List matrix4);

  @FfiNative<Void Function(Pointer<Void>)>('SceneShader::Dispose')
  external void _dispose();
}
