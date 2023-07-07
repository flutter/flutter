// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

// TODO(a14n): remove this import once Flutter 3.1 or later reaches stable (including flutter/flutter#106316)
// ignore: unnecessary_import
import 'package:flutter/painting.dart' show Color;
import 'package:flutter/services.dart';

import '../common/instance_manager.dart';
import '../common/web_kit.g.dart';
import '../foundation/foundation.dart';
import '../web_kit/web_kit.dart';
import 'ui_kit.dart';

/// Host api implementation for [UIScrollView].
class UIScrollViewHostApiImpl extends UIScrollViewHostApi {
  /// Constructs a [UIScrollViewHostApiImpl].
  UIScrollViewHostApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  })  : instanceManager = instanceManager ?? NSObject.globalInstanceManager,
        super(binaryMessenger: binaryMessenger);

  /// Sends binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with Objective-C objects.
  final InstanceManager instanceManager;

  /// Calls [createFromWebView] with the ids of the provided object instances.
  Future<void> createFromWebViewForInstances(
    UIScrollView instance,
    WKWebView webView,
  ) {
    return createFromWebView(
      instanceManager.addDartCreatedInstance(instance),
      instanceManager.getIdentifier(webView)!,
    );
  }

  /// Calls [getContentOffset] with the ids of the provided object instances.
  Future<Point<double>> getContentOffsetForInstances(
    UIScrollView instance,
  ) async {
    final List<double?> point = await getContentOffset(
      instanceManager.getIdentifier(instance)!,
    );
    return Point<double>(point[0]!, point[1]!);
  }

  /// Calls [scrollBy] with the ids of the provided object instances.
  Future<void> scrollByForInstances(
    UIScrollView instance,
    Point<double> offset,
  ) {
    return scrollBy(
      instanceManager.getIdentifier(instance)!,
      offset.x,
      offset.y,
    );
  }

  /// Calls [setContentOffset] with the ids of the provided object instances.
  Future<void> setContentOffsetForInstances(
    UIScrollView instance,
    Point<double> offset,
  ) async {
    return setContentOffset(
      instanceManager.getIdentifier(instance)!,
      offset.x,
      offset.y,
    );
  }
}

/// Host api implementation for [UIView].
class UIViewHostApiImpl extends UIViewHostApi {
  /// Constructs a [UIViewHostApiImpl].
  UIViewHostApiImpl({
    this.binaryMessenger,
    InstanceManager? instanceManager,
  })  : instanceManager = instanceManager ?? NSObject.globalInstanceManager,
        super(binaryMessenger: binaryMessenger);

  /// Sends binary data across the Flutter platform barrier.
  ///
  /// If it is null, the default BinaryMessenger will be used which routes to
  /// the host platform.
  final BinaryMessenger? binaryMessenger;

  /// Maintains instances stored to communicate with Objective-C objects.
  final InstanceManager instanceManager;

  /// Calls [setBackgroundColor] with the ids of the provided object instances.
  Future<void> setBackgroundColorForInstances(
    UIView instance,
    Color? color,
  ) async {
    return setBackgroundColor(
      instanceManager.getIdentifier(instance)!,
      color?.value,
    );
  }

  /// Calls [setOpaque] with the ids of the provided object instances.
  Future<void> setOpaqueForInstances(
    UIView instance,
    bool opaque,
  ) async {
    return setOpaque(instanceManager.getIdentifier(instance)!, opaque);
  }
}
