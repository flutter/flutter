// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../common/instance_manager.dart';
import '../common/web_kit.pigeon.dart';
import 'foundation.dart';

Iterable<NSKeyValueObservingOptionsEnumData>
    _toNSKeyValueObservingOptionsEnumData(
  Iterable<NSKeyValueObservingOptions> options,
) {
  return options.map<NSKeyValueObservingOptionsEnumData>((
    NSKeyValueObservingOptions option,
  ) {
    late final NSKeyValueObservingOptionsEnum? value;
    switch (option) {
      case NSKeyValueObservingOptions.newValue:
        value = NSKeyValueObservingOptionsEnum.newValue;
        break;
      case NSKeyValueObservingOptions.oldValue:
        value = NSKeyValueObservingOptionsEnum.oldValue;
        break;
      case NSKeyValueObservingOptions.initialValue:
        value = NSKeyValueObservingOptionsEnum.initialValue;
        break;
      case NSKeyValueObservingOptions.priorNotification:
        value = NSKeyValueObservingOptionsEnum.priorNotification;
        break;
    }

    return NSKeyValueObservingOptionsEnumData(value: value);
  });
}

extension _NSKeyValueChangeKeyEnumDataConverter on NSKeyValueChangeKeyEnumData {
  NSKeyValueChangeKey toNSKeyValueChangeKey() {
    return NSKeyValueChangeKey.values.firstWhere(
      (NSKeyValueChangeKey element) => element.name == value.name,
    );
  }
}

/// Handles initialization of Flutter APIs for the Foundation library.
class FoundationFlutterApis {
  /// Constructs a [FoundationFlutterApis].
  @visibleForTesting
  FoundationFlutterApis({
    BinaryMessenger? binaryMessenger,
    InstanceManager? instanceManager,
  })  : _binaryMessenger = binaryMessenger,
        object = NSObjectFlutterApiImpl(
          instanceManager: instanceManager,
        );

  static FoundationFlutterApis _instance = FoundationFlutterApis();

  /// Sets the global instance containing the Flutter Apis for the Foundation library.
  @visibleForTesting
  static set instance(FoundationFlutterApis instance) {
    _instance = instance;
  }

  /// Global instance containing the Flutter Apis for the Foundation library.
  static FoundationFlutterApis get instance {
    return _instance;
  }

  final BinaryMessenger? _binaryMessenger;
  bool _hasBeenSetUp = false;

  /// Flutter Api for [NSObject].
  @visibleForTesting
  final NSObjectFlutterApiImpl object;

  /// Ensures all the Flutter APIs have been set up to receive calls from native code.
  void ensureSetUp() {
    if (!_hasBeenSetUp) {
      NSObjectFlutterApi.setup(
        object,
        binaryMessenger: _binaryMessenger,
      );
      _hasBeenSetUp = true;
    }
  }
}

/// Host api implementation for [NSObject].
class NSObjectHostApiImpl extends NSObjectHostApi {
  /// Constructs an [NSObjectHostApiImpl].
  NSObjectHostApiImpl({
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

  /// Calls [addObserver] with the ids of the provided object instances.
  Future<void> addObserverForInstances(
    NSObject instance,
    NSObject observer,
    String keyPath,
    Set<NSKeyValueObservingOptions> options,
  ) {
    return addObserver(
      instanceManager.getIdentifier(instance)!,
      instanceManager.getIdentifier(observer)!,
      keyPath,
      _toNSKeyValueObservingOptionsEnumData(options).toList(),
    );
  }

  /// Calls [removeObserver] with the ids of the provided object instances.
  Future<void> removeObserverForInstances(
    NSObject instance,
    NSObject observer,
    String keyPath,
  ) {
    return removeObserver(
      instanceManager.getIdentifier(instance)!,
      instanceManager.getIdentifier(observer)!,
      keyPath,
    );
  }
}

/// Flutter api implementation for [NSObject].
class NSObjectFlutterApiImpl extends NSObjectFlutterApi {
  /// Constructs a [NSObjectFlutterApiImpl].
  NSObjectFlutterApiImpl({InstanceManager? instanceManager})
      : instanceManager = instanceManager ?? NSObject.globalInstanceManager;

  /// Maintains instances stored to communicate with native language objects.
  final InstanceManager instanceManager;

  NSObject _getObject(int identifier) {
    return instanceManager.getInstanceWithWeakReference(identifier)!;
  }

  @override
  void observeValue(
    int identifier,
    String keyPath,
    int objectIdentifier,
    List<NSKeyValueChangeKeyEnumData?> changeKeys,
    List<Object?> changeValues,
  ) {
    final void Function(String, NSObject, Map<NSKeyValueChangeKey, Object?>)?
        function = _getObject(identifier).observeValue;
    function?.call(
      keyPath,
      instanceManager.getInstanceWithWeakReference(objectIdentifier)!
          as NSObject,
      Map<NSKeyValueChangeKey, Object?>.fromIterables(
          changeKeys.map<NSKeyValueChangeKey>(
        (NSKeyValueChangeKeyEnumData? data) {
          return data!.toNSKeyValueChangeKey();
        },
      ), changeValues),
    );
  }

  @override
  void dispose(int identifier) {
    instanceManager.remove(identifier);
  }
}
