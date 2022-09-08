// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'asset_bundle.dart';
import 'binary_messenger.dart';
import 'hardware_keyboard.dart';
import 'message_codec.dart';
import 'restoration.dart';
import 'system_channels.dart';
import 'text_input.dart';

export 'dart:ui' show ChannelBuffers;

export 'binary_messenger.dart' show BinaryMessenger;
export 'hardware_keyboard.dart' show HardwareKeyboard, KeyEventManager;
export 'restoration.dart' show RestorationManager;

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
    _initKeyboard();
    initLicenses();
    SystemChannels.system.setMessageHandler((dynamic message) => handleSystemMessage(message as Object));
    SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);
    SystemChannels.platform.setMethodCallHandler(_handlePlatformMessage);
    TextInput.ensureInitialized();
    readInitialLifecycleStateFromNativeWindow();
  }

  /// The current [ServicesBinding], if one has been created.
  ///
  /// Provides access to the features exposed by this mixin. The binding must
  /// be initialized before using this getter; this is typically done by calling
  /// [runApp] or [WidgetsFlutterBinding.ensureInitialized].
  static ServicesBinding get instance => BindingBase.checkInstance(_instance);
  static ServicesBinding? _instance;

  /// The global singleton instance of [HardwareKeyboard], which can be used to
  /// query keyboard states.
  HardwareKeyboard get keyboard => _keyboard;
  late final HardwareKeyboard _keyboard;

  /// The global singleton instance of [KeyEventManager], which is used
  /// internally to dispatch key messages.
  KeyEventManager get keyEventManager => _keyEventManager;
  late final KeyEventManager _keyEventManager;

  void _initKeyboard() {
    _keyboard = HardwareKeyboard();
    _keyEventManager = KeyEventManager(_keyboard, RawKeyboard.instance);
    platformDispatcher.onKeyData = _keyEventManager.handleKeyData;
    SystemChannels.keyEvent.setMessageHandler(_keyEventManager.handleRawKeyMessage);
  }

  /// The default instance of [BinaryMessenger].
  ///
  /// This is used to send messages from the application to the platform, and
  /// keeps track of which handlers have been registered on each channel so
  /// it may dispatch incoming messages to the registered handler.
  ///
  /// The default implementation returns a [BinaryMessenger] that delivers the
  /// messages in the same order in which they are sent.
  BinaryMessenger get defaultBinaryMessenger => _defaultBinaryMessenger;
  late final BinaryMessenger _defaultBinaryMessenger;

  /// A token that represents the root isolate, used for coordinating with background
  /// isolates.
  ///
  /// This property is primarily intended for use with
  /// [BackgroundIsolateBinaryMessenger.ensureInitialized], which takes a
  /// [RootIsolateToken] as its argument. The value `null` is returned when
  /// executed from background isolates.
  ui.RootIsolateToken? get rootIsolateToken => ui.RootIsolateToken.instance;

  /// Returns `true` if executed on a background (non-root) isolate.
  ///
  /// The value `false` will always be returned on web since there is no notion
  /// of root/background isolates on the web.
  bool get useBackgroundIsolateBinaryMessenger => !kIsWeb && rootIsolateToken == null;

  /// The low level buffering and dispatch mechanism for messages sent by
  /// plugins on the engine side to their corresponding plugin code on
  /// the framework side.
  ///
  /// This exposes the [dart:ui.channelBuffers] object. Bindings can override
  /// this getter to intercept calls to the [ChannelBuffers] mechanism (for
  /// example, for tests).
  ///
  /// In production, direct access to this object should not be necessary.
  /// Messages are received and dispatched by the [defaultBinaryMessenger]. This
  /// object is primarily used to send mock messages in tests, via the
  /// [ChannelBuffers.push] method (simulating a plugin sending a message to the
  /// framework).
  ///
  /// See also:
  ///
  ///  * [PlatformDispatcher.sendPlatformMessage], which is used for sending
  ///    messages to plugins from the framework (the opposite of
  ///    [channelBuffers]).
  ///  * [platformDispatcher], the [PlatformDispatcher] singleton.
  ui.ChannelBuffers get channelBuffers => ui.channelBuffers;

  /// Creates a default [BinaryMessenger] instance that can be used for sending
  /// platform messages.
  ///
  /// Many Flutter framework components that communicate with the platform
  /// assume messages are received by the platform in the same order in which
  /// they are sent. When overriding this method, be sure the [BinaryMessenger]
  /// implementation guarantees FIFO delivery.
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
  void handleMemoryPressure() {
    rootBundle.clear();
  }

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

  Stream<LicenseEntry> _addLicenses() {
    late final StreamController<LicenseEntry> controller;
    controller = StreamController<LicenseEntry>(
      onListen: () async {
        late final String rawLicenses;
        if (kIsWeb) {
          // NOTICES for web isn't compressed since we don't have access to
          // dart:io on the client side and it's already compressed between
          // the server and client.
          rawLicenses = await rootBundle.loadString('NOTICES', cache: false);
        } else {
          // The compressed version doesn't have a more common .gz extension
          // because gradle for Android non-transparently manipulates .gz files.
          final ByteData licenseBytes = await rootBundle.load('NOTICES.Z');
          final List<int> unzippedBytes = await compute<List<int>, List<int>>(gzip.decode, licenseBytes.buffer.asUint8List(), debugLabel: 'decompressLicenses');
          rawLicenses = await compute<List<int>, String>(utf8.decode, unzippedBytes, debugLabel: 'utf8DecodeLicenses');
        }
        final List<LicenseEntry> licenses = await compute<String, List<LicenseEntry>>(_parseLicenses, rawLicenses, debugLabel: 'parseLicenses');
        licenses.forEach(controller.add);
        await controller.close();
      },
    );
    return controller.stream;
  }

  // This is run in another isolate created by _addLicenses above.
  static List<LicenseEntry> _parseLicenses(String rawLicenses) {
    final String licenseSeparator = '\n${'-' * 80}\n';
    final List<LicenseEntry> result = <LicenseEntry>[];
    final List<String> licenses = rawLicenses.split(licenseSeparator);
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
  /// [dart:ui.PlatformDispatcher.initialLifecycleState].
  ///
  /// Once the [lifecycleState] is populated through any means (including this
  /// method), this method will do nothing. This is because the
  /// [dart:ui.PlatformDispatcher.initialLifecycleState] may already be
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
    final AppLifecycleState? state = _parseAppLifecycleMessage(platformDispatcher.initialLifecycleState);
    if (state != null) {
      handleAppLifecycleStateChanged(state);
    }
  }

  Future<String?> _handleLifecycleMessage(String? message) async {
    handleAppLifecycleStateChanged(_parseAppLifecycleMessage(message!)!);
    return null;
  }

  Future<void> _handlePlatformMessage(MethodCall methodCall) async {
    final String method = methodCall.method;
    // There is only one incoming method call currently possible.
    assert(method == 'SystemChrome.systemUIChange');
    final List<dynamic> args = methodCall.arguments as List<dynamic>;
    if (_systemUiChangeCallback != null) {
      await _systemUiChangeCallback!(args[0] as bool);
    }
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

  SystemUiChangeCallback? _systemUiChangeCallback;

  /// Sets the callback for the `SystemChrome.systemUIChange` method call
  /// received on the [SystemChannels.platform] channel.
  ///
  /// This is typically not called directly. System UI changes that this method
  /// responds to are associated with [SystemUiMode]s, which are configured
  /// using [SystemChrome]. Use [SystemChrome.setSystemUIChangeCallback] to configure
  /// along with other SystemChrome settings.
  ///
  /// See also:
  ///
  ///   * [SystemChrome.setEnabledSystemUIMode], which specifies the
  ///     [SystemUiMode] to have visible when the application is running.
  // ignore: use_setters_to_change_properties, (API predates enforcing the lint)
  void setSystemUiChangeCallback(SystemUiChangeCallback? callback) {
    _systemUiChangeCallback = callback;
  }

}

/// Signature for listening to changes in the [SystemUiMode].
///
/// Set by [SystemChrome.setSystemUIChangeCallback].
typedef SystemUiChangeCallback = Future<void> Function(bool systemOverlaysAreVisible);

/// The default implementation of [BinaryMessenger].
///
/// This messenger sends messages from the app-side to the platform-side and
/// dispatches incoming messages from the platform-side to the appropriate
/// handler.
class _DefaultBinaryMessenger extends BinaryMessenger {
  const _DefaultBinaryMessenger._();

  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? message,
    ui.PlatformMessageResponseCallback? callback,
  ) async {
    ui.channelBuffers.push(channel, message, (ByteData? data) {
      if (callback != null) {
        callback(data);
      }
    });
  }

  @override
  Future<ByteData?> send(String channel, ByteData? message) {
    final Completer<ByteData?> completer = Completer<ByteData?>();
    // ui.PlatformDispatcher.instance is accessed directly instead of using
    // ServicesBinding.instance.platformDispatcher because this method might be
    // invoked before any binding is initialized. This issue was reported in
    // #27541. It is not ideal to statically access
    // ui.PlatformDispatcher.instance because the PlatformDispatcher may be
    // dependency injected elsewhere with a different instance. However, static
    // access at this location seems to be the least bad option.
    // TODO(ianh): Use ServicesBinding.instance once we have better diagnostics
    // on that getter.
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
  void setMessageHandler(String channel, MessageHandler? handler) {
    if (handler == null) {
      ui.channelBuffers.clearListener(channel);
    } else {
      ui.channelBuffers.setListener(channel, (ByteData? data, ui.PlatformMessageResponseCallback callback) async {
        ByteData? response;
        try {
          response = await handler(data);
        } catch (exception, stack) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'services library',
            context: ErrorDescription('during a platform message callback'),
          ));
        } finally {
          callback(response);
        }
      });
    }
  }
}
