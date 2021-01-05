// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'asset_bundle.dart';
import 'binary_messenger.dart';
import 'restoration.dart';
import 'system_channels.dart';

/// Listens for platform messages and directs them to the [defaultBinaryMessenger].
///
/// The [ServicesBinding] also registers a [LicenseEntryCollector] that exposes
/// the licenses found in the `LICENSE` file stored at the root of the asset
/// bundle, and implements the `ext.flutter.evict` service extension (see
/// [evict]).
mixin ServicesBinding on BindingBase, SchedulerBinding {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _defaultBinaryMessenger = createBinaryMessenger();
    _restorationManager = createRestorationManager();
    window.onPlatformMessage = defaultBinaryMessenger.handlePlatformMessage;
    initLicenses();
    SystemChannels.system.setMessageHandler((dynamic message) => handleSystemMessage(message as Object));
    SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);
    readInitialLifecycleStateFromNativeWindow();
  }

  /// The current [ServicesBinding], if one has been created.
  static ServicesBinding? get instance => _instance;
  static ServicesBinding? _instance;

  /// The default instance of [BinaryMessenger].
  ///
  /// This is used to send messages from the application to the platform, and
  /// keeps track of which handlers have been registered on each channel so
  /// it may dispatch incoming messages to the registered handler.
  BinaryMessenger get defaultBinaryMessenger => _defaultBinaryMessenger;
  late BinaryMessenger _defaultBinaryMessenger;

  /// Creates a default [BinaryMessenger] instance that can be used for sending
  /// platform messages.
  @protected
  BinaryMessenger createBinaryMessenger() {
    return const _DefaultBinaryMessenger._();
  }


  /// Called when the operating system notifies the application of a memory
  /// pressure situation.
  ///
  /// This method exposes the `memoryPressure` notification from
  /// [SystemChannels.system].
  @protected
  @mustCallSuper
  void handleMemoryPressure() { }

  /// Handler called for messages received on the [SystemChannels.system]
  /// message channel.
  ///
  /// Other bindings may override this to respond to incoming system messages.
  @protected
  @mustCallSuper
  Future<void> handleSystemMessage(Object systemMessage) async {
    final Map<String, dynamic> message = systemMessage as Map<String, dynamic>;
    final String type = message['type'] as String;
    switch (type) {
      case 'memoryPressure':
        handleMemoryPressure();
        break;
    }
    return;
  }

  /// Adds relevant licenses to the [LicenseRegistry].
  ///
  /// By default, the [ServicesBinding]'s implementation of [initLicenses] adds
  /// all the licenses collected by the `flutter` tool during compilation.
  @protected
  @mustCallSuper
  void initLicenses() {
    LicenseRegistry.addLicense(_addLicenses);
  }

  Stream<LicenseEntry> _addLicenses() async* {
    // Using _something_ here to break
    // this into two parts is important because isolates take a while to copy
    // data at the moment, and if we receive the data in the same event loop
    // iteration as we send the data to the next isolate, we are definitely
    // going to miss frames. Another solution would be to have the work all
    // happen in one isolate, and we may go there eventually, but first we are
    // going to see if isolate communication can be made cheaper.
    // See: https://github.com/dart-lang/sdk/issues/31959
    //      https://github.com/dart-lang/sdk/issues/31960
    // TODO(ianh): Remove this complexity once these bugs are fixed.
    final Completer<String> rawLicenses = Completer<String>();
    scheduleTask(() async {
      rawLicenses.complete(await rootBundle.loadString('NOTICES', cache: false));
    }, Priority.animation);
    await rawLicenses.future;
    final Completer<List<LicenseEntry>> parsedLicenses = Completer<List<LicenseEntry>>();
    scheduleTask(() async {
      parsedLicenses.complete(compute<String, List<LicenseEntry>>(_parseLicenses, await rawLicenses.future, debugLabel: 'parseLicenses'));
    }, Priority.animation);
    await parsedLicenses.future;
    yield* Stream<LicenseEntry>.fromIterable(await parsedLicenses.future);
  }

  // This is run in another isolate created by _addLicenses above.
  static List<LicenseEntry> _parseLicenses(String rawLicenses) {
    final String _licenseSeparator = '\n' + ('-' * 80) + '\n';
    final List<LicenseEntry> result = <LicenseEntry>[];
    final List<String> licenses = rawLicenses.split(_licenseSeparator);
    for (final String license in licenses) {
      final int split = license.indexOf('\n\n');
      if (split >= 0) {
        result.add(LicenseEntryWithLineBreaks(
          license.substring(0, split).split('\n'),
          license.substring(split + 2),
        ));
      } else {
        result.add(LicenseEntryWithLineBreaks(const <String>[], license));
      }
    }
    return result;
  }

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    assert(() {
      registerStringServiceExtension(
        // ext.flutter.evict value=foo.png will cause foo.png to be evicted from
        // the rootBundle cache and cause the entire image cache to be cleared.
        // This is used by hot reload mode to clear out the cache of resources
        // that have changed.
        name: 'evict',
        getter: () async => '',
        setter: (String value) async {
          evict(value);
        },
      );
      return true;
    }());
  }

  /// Called in response to the `ext.flutter.evict` service extension.
  ///
  /// This is used by the `flutter` tool during hot reload so that any images
  /// that have changed on disk get cleared from caches.
  @protected
  @mustCallSuper
  void evict(String asset) {
    rootBundle.evict(asset);
  }

  // App life cycle

  /// Initializes the [lifecycleState] with the
  /// [dart:ui.SingletonFlutterWindow.initialLifecycleState].
  ///
  /// Once the [lifecycleState] is populated through any means (including this
  /// method), this method will do nothing. This is because the
  /// [dart:ui.SingletonFlutterWindow.initialLifecycleState] may already be
  /// stale and it no longer makes sense to use the initial state at dart vm
  /// startup as the current state anymore.
  ///
  /// The latest state should be obtained by subscribing to
  /// [WidgetsBindingObserver.didChangeAppLifecycleState].
  @protected
  void readInitialLifecycleStateFromNativeWindow() {
    if (lifecycleState != null) {
      return;
    }
    final AppLifecycleState? state = _parseAppLifecycleMessage(window.initialLifecycleState);
    if (state != null) {
      handleAppLifecycleStateChanged(state);
    }
  }

  Future<String?> _handleLifecycleMessage(String? message) async {
    handleAppLifecycleStateChanged(_parseAppLifecycleMessage(message!)!);
    return null;
  }

  static AppLifecycleState? _parseAppLifecycleMessage(String message) {
    switch (message) {
      case 'AppLifecycleState.paused':
        return AppLifecycleState.paused;
      case 'AppLifecycleState.resumed':
        return AppLifecycleState.resumed;
      case 'AppLifecycleState.inactive':
        return AppLifecycleState.inactive;
      case 'AppLifecycleState.detached':
        return AppLifecycleState.detached;
    }
    return null;
  }

  /// The [RestorationManager] synchronizes the restoration data between
  /// engine and framework.
  ///
  /// See the docs for [RestorationManager] for a discussion of restoration
  /// state and how it is organized in Flutter.
  ///
  /// To use a different [RestorationManager] subclasses can override
  /// [createRestorationManager], which is called to create the instance
  /// returned by this getter.
  RestorationManager get restorationManager => _restorationManager;
  late RestorationManager _restorationManager;

  /// Creates the [RestorationManager] instance available via
  /// [restorationManager].
  ///
  /// Can be overridden in subclasses to create a different [RestorationManager].
  @protected
  RestorationManager createRestorationManager() {
    return RestorationManager();
  }
}

/// The default implementation of [BinaryMessenger].
///
/// This messenger sends messages from the app-side to the platform-side and
/// dispatches incoming messages from the platform-side to the appropriate
/// handler.
class _DefaultBinaryMessenger extends BinaryMessenger {
  const _DefaultBinaryMessenger._();

  // Handlers for incoming messages from platform plugins.
  // This is static so that this class can have a const constructor.
  static final Map<String, MessageHandler> _handlers =
      <String, MessageHandler>{};

  // Mock handlers that intercept and respond to outgoing messages.
  // This is static so that this class can have a const constructor.
  static final Map<String, MessageHandler> _mockHandlers =
      <String, MessageHandler>{};

  Future<ByteData?> _sendPlatformMessage(String channel, ByteData? message) {
    final Completer<ByteData?> completer = Completer<ByteData?>();
    // ui.PlatformDispatcher.instance is accessed directly instead of using
    // ServicesBinding.instance.platformDispatcher because this method might be
    // invoked before any binding is initialized. This issue was reported in
    // #27541. It is not ideal to statically access
    // ui.PlatformDispatcher.instance because the PlatformDispatcher may be
    // dependency injected elsewhere with a different instance. However, static
    // access at this location seems to be the least bad option.
    ui.PlatformDispatcher.instance.sendPlatformMessage(channel, message, (ByteData? reply) {
      try {
        completer.complete(reply);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: ErrorDescription('during a platform message response callback'),
        ));
      }
    });
    return completer.future;
  }

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    ui.PlatformMessageResponseCallback? callback,
  ) async {
    ByteData? response;
    try {
      final MessageHandler? handler = _handlers[channel];
      if (handler != null) {
        response = await handler(data);
      } else {
        ui.channelBuffers.push(channel, data, callback!);
        callback = null;
      }
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: ErrorDescription('during a platform message callback'),
      ));
    } finally {
      if (callback != null) {
        callback(response);
      }
    }
  }

  @override
  Future<ByteData?>? send(String channel, ByteData? message) {
    final MessageHandler? handler = _mockHandlers[channel];
    if (handler != null)
      return handler(message);
    return _sendPlatformMessage(channel, message);
  }

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {
    if (handler == null) {
      _handlers.remove(channel);
    } else {
      _handlers[channel] = handler;
      ui.channelBuffers.drain(channel, (ByteData? data, ui.PlatformMessageResponseCallback callback) async {
        await handlePlatformMessage(channel, data, callback);
      });
    }
  }

  @override
  bool checkMessageHandler(String channel, MessageHandler? handler) => _handlers[channel] == handler;

  @override
  void setMockMessageHandler(String channel, MessageHandler? handler) {
    if (handler == null)
      _mockHandlers.remove(channel);
    else
      _mockHandlers[channel] = handler;
  }

  @override
  bool checkMockMessageHandler(String channel, MessageHandler? handler) => _mockHandlers[channel] == handler;
}
