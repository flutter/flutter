// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Implements the Android native overscroll effect identically in Flutter.
/// 
/// This widget only supported with Impeller rendering engine.
class StretchOverscrollEffect extends StatefulWidget {
  const StretchOverscrollEffect({
    super.key,
    this.overscrollX = 0,
    this.overscrollY = 0,
    required this.child
  }) : assert(ui.ImageFilter.isShaderFilterSupported);

  /// The horizontal overscroll amount applied for stretching effect,
  /// and value should be between -1 and 1 inclusive.
  final double overscrollX;

  /// The vertical overscroll amount applied for stretching effect,
  /// and value should be between -1 and 1 inclusive.
  final double overscrollY;

  /// The child widget that receives the stretching overscroll effect.
  final Widget child;

  @override
  State<StretchOverscrollEffect> createState() => _StretchOverscrollEffectState();
}

class _StretchOverscrollEffectState extends State<StretchOverscrollEffect> {
  @override
  Widget build(BuildContext context) {
    if (_StretchOverscrollEffectShader._initialized) {
      final bool isShaderNeeded = widget.overscrollX != 0.0 || widget.overscrollY != 0.0;
      final ui.FragmentShader shader = _StretchOverscrollEffectShader._program!.fragmentShader();
      shader.setFloat(2, 1.0);
      shader.setFloat(3, widget.overscrollX);
      shader.setFloat(4, widget.overscrollY);
      shader.setFloat(5, 0.7);

      return ImageFiltered(
        imageFilter: ui.ImageFilter.shader(shader),
        enabled: isShaderNeeded,
        // A nearly-transparent box is used to ensure the shader gets applied,
        // even when the child is visually transparent or has no paint operations.
        child: ColoredBox(
          color: Color.fromRGBO(0, 0, 0, 0.0000001),
          child: widget.child,
        ),
      );
    } else {
      if (!_StretchOverscrollEffectShader._initCalled) {
        _StretchOverscrollEffectShader.initializeShader();
      }

      _StretchOverscrollEffectShader.addListener(() => setState(() {
        // Updates the widget state to use [ImageFiltered] after the fragment shader is loaded.
      }));
    }

    return widget.child;
  }
}

class _StretchOverscrollEffectShader {
  static bool _initCalled = false;
  static bool _initialized = false;
  static ui.FragmentProgram? _program;
  static List<VoidCallback> _listeners = [];

  static void initializeShader() {
    if (!_initCalled) {
      ui.FragmentProgram.fromAsset('shaders/stretch_overscroll.frag').then((ui.FragmentProgram program) {
        _program = program;
        _initialized = true;
        notifyListeners();
      });
      _initCalled = true;
    }
  }

  static void addListener(VoidCallback listener) {
    assert(!_listeners.contains(listener));
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    assert(_listeners.contains(listener));
    _listeners.remove(listener);
  }

  static void notifyListeners() {
    for (final listener in _listeners) {
      listener.call();
    }
  }
}