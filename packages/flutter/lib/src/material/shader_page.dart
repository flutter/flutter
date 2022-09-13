// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'page_transitions_theme.dart';

/// Example format:
///
/// ```glsl
/// layout (location = 0) uniform float animation;
/// layout (location = 1) uniform float width;
/// layout (location = 2) uniform float height;
/// layout (location = 3) uniform sampler2D source;
/// ```
///
///
class ShaderPageTransitionBuilder extends PageTransitionsBuilder {
  const ShaderPageTransitionBuilder({required this.shader});

  /// The name of the shader asset to use.
  final String shader;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _ShaderPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      fragmentProgram: ui.FragmentProgram.fromAsset(shader),
      child: child,
    );
  }  
}

class _ShaderPageTransition extends StatelessWidget {
  const _ShaderPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.fragmentProgram,
    this.child,
  }) : assert(animation != null),
       assert(secondaryAnimation != null);

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Future<ui.FragmentProgram> fragmentProgram;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DualTransitionBuilder(
      animation: animation,
      forwardBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return _ShaderEnterTransition(
          animation: animation,
          fragmentProgram: fragmentProgram,
          child: child,
        );
      },
      reverseBuilder: (
        BuildContext context,
        Animation<double> animation,
        Widget? child,
      ) {
        return _ShaderEnterTransition(
          animation: animation,
          fragmentProgram: fragmentProgram,
          reverse: true,
          child: child,
        );
      },
      child: child,
    );
  }
}

class _ShaderEnterTransition extends StatefulWidget {
  const _ShaderEnterTransition({
    required this.animation,
    this.reverse = false,
    required this.fragmentProgram,
    this.child,
  }) : assert(animation != null),
       assert(reverse != null);

  final Animation<double> animation;
  final Widget? child;
  final Future<ui.FragmentProgram> fragmentProgram;
  final bool reverse;

  @override
  State<_ShaderEnterTransition> createState() => _ShaderEnterTransitionState();
}

class _ShaderEnterTransitionState extends State<_ShaderEnterTransition> with _ShaderTransitionBase {
  @override
  bool get useSnapshot => !kIsWeb;

  late _ShaderEnterTransitionPainter delegate;

  static final Animatable<double> _shaderInTransition = Tween<double>(
    begin: 0.0,
    end: 1.00,
  );

  static final Animatable<double> _shaderOutTransition = Tween<double>(
    begin: 1.0,
    end: 0.00,
  );

  void _updateAnimations() {
    shaderTransition = (widget.reverse
      ? _shaderOutTransition
      : _shaderInTransition
    ).animate(widget.animation);

    widget.animation.addListener(onAnimationValueChange);
    widget.animation.addStatusListener(onAnimationStatusChange);
  }

  @override
  void initState() {
    _updateAnimations();
    delegate = _ShaderEnterTransitionPainter(
      animation: shaderTransition,
      fragmentProgram: widget.fragmentProgram,
    );
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _ShaderEnterTransition oldWidget) {
    if (oldWidget.reverse != widget.reverse || oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(onAnimationStatusChange);
      _updateAnimations();
      delegate.dispose();
      delegate = _ShaderEnterTransitionPainter(
        animation: shaderTransition,
        fragmentProgram: widget.fragmentProgram,
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.animation.removeListener(onAnimationValueChange);
    widget.animation.removeStatusListener(onAnimationStatusChange);
    delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SnapshotWidget(
      painter: delegate,
      controller: controller,
      mode: SnapshotMode.permissive,
      child: widget.child,
    );
  }
}

mixin _ShaderTransitionBase {
  bool get useSnapshot;

  final SnapshotController controller = SnapshotController();

  late Animation<double> shaderTransition;

  void onAnimationValueChange() {
    if (shaderTransition.value == 1.0) {
      controller.allowSnapshotting = false;
    } else {
      controller.allowSnapshotting = useSnapshot;
    }
  }

  void onAnimationStatusChange(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        controller.allowSnapshotting = false;
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        controller.allowSnapshotting = useSnapshot;
        break;
    }
  }
}

final Float64List _identityMatrix = Float64List.fromList(const <double>[
  1, 0, 0, 0,
  0, 1, 0, 0,
  0, 0, 1, 0,
  0, 0, 0, 1,
]);

class _ShaderEnterTransitionPainter extends SnapshotPainter {
  _ShaderEnterTransitionPainter({
    required this.animation,
    required Future<ui.FragmentProgram> fragmentProgram,
  }) {
    fragmentProgram.then((ui.FragmentProgram program) {
      if (_disposed) {
        return;
      }
      fragmentShader = program.fragmentShader();
    });
    animation.addListener(notifyListeners);
  }

  bool _disposed = false;
  final Animation<double> animation;
  ui.FragmentShader? fragmentShader;

  ui.Image? _cachedImage;
  ImageShader? _cachedImageShader;

  @override
  void paint(
    PaintingContext context,
    ui.Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) {
    painter(context, offset);
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    double pixelRatio,
  ) {
    if (image != _cachedImage) {
      _cachedImage = image;
      _cachedImageShader?.dispose();
      _cachedImageShader = ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        _identityMatrix,
      );
    }
    if (fragmentShader == null) {
      context.canvas.drawRect(
        offset & size,
        Paint()..shader = fragmentShader,
      );
      return;
    }
    fragmentShader!
      ..setFloat(0, animation.value)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height)
      ..setSampler(0, _cachedImageShader!);
    context.canvas.drawRect(
      offset & size,
      Paint()..shader = fragmentShader,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    animation.removeListener(notifyListeners);
    fragmentShader?.dispose();
    _cachedImageShader?.dispose();
    super.dispose();
  }

  @override
  bool shouldRepaint(covariant _ShaderEnterTransitionPainter oldPainter) {
    return oldPainter.animation.value != animation.value;
  }
}
