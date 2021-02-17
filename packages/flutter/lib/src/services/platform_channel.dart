// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'binary_messenger.dart';
import 'binding.dart';
import 'message_codec.dart';
import 'message_codecs.dart';

/// A named channel for communicating with platform plugins using asynchronous
/// message passing.
///
/// Messages are encoded into binary before being sent, and binary messages
/// received are decoded into Dart values. The [MessageCodec] used must be
/// compatible with the one used by the platform plugin. This can be achieved
/// by creating a basic message channel counterpart of this channel on the
/// platform side. The Dart type of messages sent and received is [T],
/// but only the values supported by the specified [MessageCodec] can be used.
/// The use of unsupported values should be considered programming errors, and
/// will result in exceptions being thrown. The null message is supported
/// for all codecs.
///
/// The logical identity of the channel is given by its name. Identically named
/// channels will interfere with each other's communication.
///
/// See: <https://flutter.dev/platform-channels/>
class BasicMessageChannel<T> {
  /// Creates a [BasicMessageChannel] with the specified [name], [codec] and [binaryMessenger].
  ///
  /// The [name] and [codec] arguments cannot be null. The default [ServicesBinding.defaultBinaryMessenger]
  /// instance is used if [binaryMessenger] is null.
  const BasicMessageChannel(this.name, this.codec, { BinaryMessenger? binaryMessenger })
      : assert(name != null),
        assert(codec != null),
        _binaryMessenger = binaryMessenger;

  /// The logical channel on which communication happens, not null.
  final String name;

  /// The message codec used by this channel, not null.
  final MessageCodec<T> codec;

  /// The messenger which sends the bytes for this channel, not null.
  BinaryMessenger get binaryMessenger => _binaryMessenger ?? ServicesBinding.instance!.defaultBinaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  /// Sends the specified [message] to the platform plugins on this channel.
  ///
  /// Returns a [Future] which completes to the received response, which may
  /// be null.
  Future<T?> send(T message) async {
    return codec.decodeMessage(await binaryMessenger.send(name, codec.encodeMessage(message)));
  }

  /// Sets a callback for receiving messages from the platform plugins on this
  /// channel. Messages may be null.
  ///
  /// The given callback will replace the currently registered callback for this
  /// channel, if any. To remove the handler, pass null as the `handler`
  /// argument.
  ///
  /// The handler's return value is sent back to the platform plugins as a
  /// message reply. It may be null.
  void setMessageHandler(Future<T> Function(T? message)? handler) {
    if (handler == null) {
      binaryMessenger.setMessageHandler(name, null);
    } else {
      binaryMessenger.setMessageHandler(name, (ByteData? message) async {
        return codec.encodeMessage(await handler(codec.decodeMessage(message)));
      });
    }
  }

  /// Sets a mock callback for intercepting messages sent on this channel.
  /// Messages may be null.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// this channel, if any. To remove the mock handler, pass null as the
  /// `handler` argument.
  ///
  /// The handler's return value is used as a message reply. It may be null.
  ///
  /// This is intended for testing. Messages intercepted in this manner are not
  /// sent to platform plugins.
  void setMockMessageHandler(Future<T> Function(T? message)? handler) {
    if (handler == null) {
      binaryMessenger.setMockMessageHandler(name, null);
    } else {
      binaryMessenger.setMockMessageHandler(name, (ByteData? message) async {
        return codec.encodeMessage(await handler(codec.decodeMessage(message)));
      });
    }
  }
}

Expando<Object> _methodChannelHandlers = Expando<Object>();
Expando<Object> _methodChannelMockHandlers = Expando<Object>();

/// A named channel for communicating with platform plugins using asynchronous
/// method calls.
///
/// Method calls are encoded into binary before being sent, and binary results
/// received are decoded into Dart values. The [MethodCodec] used must be
/// compatible with the one used by the platform plugin. This can be achieved
/// by creating a method channel counterpart of this channel on the
/// platform side. The Dart type of arguments and results is `dynamic`,
/// but only values supported by the specified [MethodCodec] can be used.
/// The use of unsupported values should be considered programming errors, and
/// will result in exceptions being thrown. The null value is supported
/// for all codecs.
///
/// The logical identity of the channel is given by its name. Identically named
/// channels will interfere with each other's communication.
///
/// See: <https://flutter.dev/platform-channels/>
class MethodChannel {
  /// Creates a [MethodChannel] with the specified [name].
  ///
  /// The [codec] used will be [StandardMethodCodec], unless otherwise
  /// specified.
  ///
  /// The [name] and [codec] arguments cannot be null. The default [ServicesBinding.defaultBinaryMessenger]
  /// instance is used if [binaryMessenger] is null.
  const MethodChannel(this.name, [this.codec = const StandardMethodCodec(), BinaryMessenger? binaryMessenger ])
      : assert(name != null),
        assert(codec != null),
        _binaryMessenger = binaryMessenger;

  /// The logical channel on which communication happens, not null.
  final String name;

  /// The message codec used by this channel, not null.
  final MethodCodec codec;

  /// The messenger used by this channel to send platform messages.
  ///
  /// The messenger may not be null.
  BinaryMessenger get binaryMessenger => _binaryMessenger ?? ServicesBinding.instance!.defaultBinaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  @optionalTypeArgs
  Future<T?> _invokeMethod<T>(String method, { required bool missingOk, dynamic arguments }) async {
    assert(method != null);
    final ByteData? result = await binaryMessenger.send(
      name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
    );
    if (result == null) {
      if (missingOk) {
        return null;
      }
      throw MissingPluginException('No implementation found for method $method on channel $name');
    }
    return codec.decodeEnvelope(result) as T?;
  }

  /// Invokes a [method] on this channel with the specified [arguments].
  ///
  /// The static type of [arguments] is `dynamic`, but only values supported by
  /// the [codec] of this channel can be used. The same applies to the returned
  /// result. The values supported by the default codec and their platform-specific
  /// counterparts are documented with [StandardMessageCodec].
  ///
  /// The generic argument `T` of the method can be inferred by the surrounding
  /// context, or provided explicitly. If it does not match the returned type of
  /// the channel, a [TypeError] will be thrown at runtime. `T` cannot be a class
  /// with generics other than `dynamic`. For example, `Map<String, String>`
  /// is not supported but `Map<dynamic, dynamic>` or `Map` is.
  ///
  /// Returns a [Future] which completes to one of the following:
  ///
  /// * a result (possibly null), on successful invocation;
  /// * a [PlatformException], if the invocation failed in the platform plugin;
  /// * a [MissingPluginException], if the method has not been implemented by a
  ///   platform plugin.
  ///
  /// The following code snippets demonstrate how to invoke platform methods
  /// in Dart using a MethodChannel and how to implement those methods in Java
  /// (for Android) and Objective-C (for iOS).
  ///
  /// {@tool snippet}
  ///
  /// The code might be packaged up as a musical plugin, see
  /// <https://flutter.dev/developing-packages/>:
  ///
  /// ```dart
  /// class Music {
  ///   static const MethodChannel _channel = MethodChannel('music');
  ///
  ///   static Future<bool> isLicensed() async {
  ///     // invokeMethod returns a Future<T?>, so we handle the case where
  ///     // the return value is null by treating null as false.
  ///     return _channel.invokeMethod<bool>('isLicensed').then<bool>((bool? value) => value ?? false);
  ///   }
  ///
  ///   static Future<List<Song>> songs() async {
  ///     // invokeMethod here returns a Future<dynamic> that completes to a
  ///     // List<dynamic> with Map<dynamic, dynamic> entries. Post-processing
  ///     // code thus cannot assume e.g. List<Map<String, String>> even though
  ///     // the actual values involved would support such a typed container.
  ///     // The correct type cannot be inferred with any value of `T`.
  ///     final List<dynamic> songs = await _channel.invokeMethod('getSongs');
  ///     return songs.map(Song.fromJson).toList();
  ///   }
  ///
  ///   static Future<void> play(Song song, double volume) async {
  ///     // Errors occurring on the platform side cause invokeMethod to throw
  ///     // PlatformExceptions.
  ///     try {
  ///       return _channel.invokeMethod('play', <String, dynamic>{
  ///         'song': song.id,
  ///         'volume': volume,
  ///       });
  ///     } on PlatformException catch (e) {
  ///       throw 'Unable to play ${song.title}: ${e.message}';
  ///     }
  ///   }
  /// }
  ///
  /// class Song {
  ///   Song(this.id, this.title, this.artist);
  ///
  ///   final String id;
  ///   final String title;
  ///   final String artist;
  ///
  ///   static Song fromJson(dynamic json) {
  ///     return Song(json['id'], json['title'], json['artist']);
  ///   }
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  ///
  /// Java (for Android):
  ///
  /// ```java
  /// // Assumes existence of an Android MusicApi.
  /// public class MusicPlugin implements MethodCallHandler {
  ///   @Override
  ///   public void onMethodCall(MethodCall call, Result result) {
  ///     switch (call.method) {
  ///       case "isLicensed":
  ///         result.success(MusicApi.checkLicense());
  ///         break;
  ///       case "getSongs":
  ///         final List<MusicApi.Track> tracks = MusicApi.getTracks();
  ///         final List<Object> json = ArrayList<>(tracks.size());
  ///         for (MusicApi.Track track : tracks) {
  ///           json.add(track.toJson()); // Map<String, Object> entries
  ///         }
  ///         result.success(json);
  ///         break;
  ///       case "play":
  ///         final String song = call.argument("song");
  ///         final double volume = call.argument("volume");
  ///         try {
  ///           MusicApi.playSongAtVolume(song, volume);
  ///           result.success(null);
  ///         } catch (MusicalException e) {
  ///           result.error("playError", e.getMessage(), null);
  ///         }
  ///         break;
  ///       default:
  ///         result.notImplemented();
  ///     }
  ///   }
  ///   // Other methods elided.
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// {@tool snippet}
  ///
  /// Objective-C (for iOS):
  ///
  /// ```objectivec
  /// @interface MusicPlugin : NSObject<FlutterPlugin>
  /// @end
  ///
  /// // Assumes existence of an iOS Broadway Play Api.
  /// @implementation MusicPlugin
  /// - (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  ///   if ([@"isLicensed" isEqualToString:call.method]) {
  ///     result([NSNumber numberWithBool:[BWPlayApi isLicensed]]);
  ///   } else if ([@"getSongs" isEqualToString:call.method]) {
  ///     NSArray* items = [BWPlayApi items];
  ///     NSMutableArray* json = [NSMutableArray arrayWithCapacity:items.count];
  ///     for (final BWPlayItem* item in items) {
  ///       [json addObject:@{@"id":item.itemId, @"title":item.name, @"artist":item.artist}];
  ///     }
  ///     result(json);
  ///   } else if ([@"play" isEqualToString:call.method]) {
  ///     NSString* itemId = call.arguments[@"song"];
  ///     NSNumber* volume = call.arguments[@"volume"];
  ///     NSError* error = nil;
  ///     BOOL success = [BWPlayApi playItem:itemId volume:volume.doubleValue error:&error];
  ///     if (success) {
  ///       result(nil);
  ///     } else {
  ///       result([FlutterError errorWithCode:[NSString stringWithFormat:@"Error %ld", error.code]
  ///                                  message:error.domain
  ///                                  details:error.localizedDescription]);
  ///     }
  ///   } else {
  ///     result(FlutterMethodNotImplemented);
  ///   }
  /// }
  /// // Other methods elided.
  /// @end
  /// ```
  /// {@end-tool}
  ///
  /// See also:
  ///
  ///  * [invokeListMethod], for automatically returning typed lists.
  ///  * [invokeMapMethod], for automatically returning typed maps.
  ///  * [StandardMessageCodec] which defines the payload values supported by
  ///    [StandardMethodCodec].
  ///  * [JSONMessageCodec] which defines the payload values supported by
  ///    [JSONMethodCodec].
  ///  * <https://api.flutter.dev/javadoc/io/flutter/plugin/common/MethodCall.html>
  ///    for how to access method call arguments on Android.
  @optionalTypeArgs
  Future<T?> invokeMethod<T>(String method, [ dynamic arguments ]) {
    return _invokeMethod<T>(method, missingOk: false, arguments: arguments);
  }

  /// An implementation of [invokeMethod] that can return typed lists.
  ///
  /// Dart generics are reified, meaning that an untyped List<dynamic>
  /// cannot masquerade as a List<T>. Since invokeMethod can only return
  /// dynamic maps, we instead create a new typed list using [List.cast].
  ///
  /// See also:
  ///
  ///  * [invokeMethod], which this call delegates to.
  Future<List<T>?> invokeListMethod<T>(String method, [ dynamic arguments ]) async {
    final List<dynamic>? result = await invokeMethod<List<dynamic>?>(method, arguments);
    return result?.cast<T>();
  }

  /// An implementation of [invokeMethod] that can return typed maps.
  ///
  /// Dart generics are reified, meaning that an untyped Map<dynamic, dynamic>
  /// cannot masquerade as a Map<K, V>. Since invokeMethod can only return
  /// dynamic maps, we instead create a new typed map using [Map.cast].
  ///
  /// See also:
  ///
  ///  * [invokeMethod], which this call delegates to.
  Future<Map<K, V>?> invokeMapMethod<K, V>(String method, [ dynamic arguments ]) async {
    final Map<dynamic, dynamic>? result = await invokeMethod<Map<dynamic, dynamic>?>(method, arguments);
    return result?.cast<K, V>();
  }

  /// Sets a callback for receiving method calls on this channel.
  ///
  /// The given callback will replace the currently registered callback for this
  /// channel, if any. To remove the handler, pass null as the
  /// `handler` argument.
  ///
  /// If the future returned by the handler completes with a result, that value
  /// is sent back to the platform plugin caller wrapped in a success envelope
  /// as defined by the [codec] of this channel. If the future completes with
  /// a [PlatformException], the fields of that exception will be used to
  /// populate an error envelope which is sent back instead. If the future
  /// completes with a [MissingPluginException], an empty reply is sent
  /// similarly to what happens if no method call handler has been set.
  /// Any other exception results in an error envelope being sent.
  void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) {
    _methodChannelHandlers[this] = handler;
    binaryMessenger.setMessageHandler(
      name,
      handler == null
        ? null
        : (ByteData? message) => _handleAsMethodCall(message, handler),
    );
  }

  /// Returns true if the `handler` argument matches the `handler` previously
  /// passed to [setMethodCallHandler].
  ///
  /// This method is useful for tests or test harnesses that want to assert the
  /// handler for the specified channel has not been altered by a previous test.
  ///
  /// Passing null for the `handler` returns true if the handler for the channel
  /// is not set.
  bool checkMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) => _methodChannelHandlers[this] == handler;

  /// Sets a mock callback for intercepting method invocations on this channel.
  ///
  /// The given callback will replace the currently registered mock callback for
  /// this channel, if any. To remove the mock handler, pass null as the
  /// `handler` argument.
  ///
  /// Later calls to [invokeMethod] will result in a successful result,
  /// a [PlatformException] or a [MissingPluginException], determined by how
  /// the future returned by the mock callback completes. The [codec] of this
  /// channel is used to encode and decode values and errors.
  ///
  /// This is intended for testing. Method calls intercepted in this manner are
  /// not sent to platform plugins.
  ///
  /// The provided `handler` must return a `Future` that completes with the
  /// return value of the call. The value will be encoded using
  /// [MethodCodec.encodeSuccessEnvelope], to act as if platform plugin had
  /// returned that value.
  void setMockMethodCallHandler(Future<dynamic>? Function(MethodCall call)? handler) {
    _methodChannelMockHandlers[this] = handler;
    binaryMessenger.setMockMessageHandler(
      name,
      handler == null ? null : (ByteData? message) => _handleAsMethodCall(message, handler),
    );
  }

  /// Returns true if the `handler` argument matches the `handler` previously
  /// passed to [setMockMethodCallHandler].
  ///
  /// This method is useful for tests or test harnesses that want to assert the
  /// handler for the specified channel has not been altered by a previous test.
  ///
  /// Passing null for the `handler` returns true if the handler for the channel
  /// is not set.
  bool checkMockMethodCallHandler(Future<dynamic> Function(MethodCall call)? handler) => _methodChannelMockHandlers[this] == handler;

  Future<ByteData?> _handleAsMethodCall(ByteData? message, Future<dynamic>? handler(MethodCall call)) async {
    final MethodCall call = codec.decodeMethodCall(message);
    try {
      return codec.encodeSuccessEnvelope(await handler(call));
    } on PlatformException catch (e) {
      return codec.encodeErrorEnvelope(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    } on MissingPluginException {
      return null;
    } catch (e) {
      return codec.encodeErrorEnvelope(code: 'error', message: e.toString(), details: null);
    }
  }
}

/// A [MethodChannel] that ignores missing platform plugins.
///
/// When [invokeMethod] fails to find the platform plugin, it returns null
/// instead of throwing an exception.
class OptionalMethodChannel extends MethodChannel {
  /// Creates a [MethodChannel] that ignores missing platform plugins.
  const OptionalMethodChannel(String name, [MethodCodec codec = const StandardMethodCodec()])
    : super(name, codec);

  @override
  Future<T?> invokeMethod<T>(String method, [ dynamic arguments ]) async {
    return super._invokeMethod<T>(method, missingOk: true, arguments: arguments);
  }

  @override
  Future<List<T>?> invokeListMethod<T>(String method, [ dynamic arguments ]) async {
    final List<dynamic>? result = await invokeMethod<List<dynamic>>(method, arguments);
    return result?.cast<T>();
  }

  @override
  Future<Map<K, V>?> invokeMapMethod<K, V>(String method, [ dynamic arguments ]) async {
    final Map<dynamic, dynamic>? result = await invokeMethod<Map<dynamic, dynamic>>(method, arguments);
    return result?.cast<K, V>();
  }

}

/// A named channel for communicating with platform plugins using event streams.
///
/// Stream setup requests are encoded into binary before being sent,
/// and binary events and errors received are decoded into Dart values.
/// The [MethodCodec] used must be compatible with the one used by the platform
/// plugin. This can be achieved by creating an `EventChannel` counterpart of
/// this channel on the platform side. The Dart type of events sent and received
/// is `dynamic`, but only values supported by the specified [MethodCodec] can
/// be used.
///
/// The logical identity of the channel is given by its name. Identically named
/// channels will interfere with each other's communication.
///
/// See: <https://flutter.dev/platform-channels/>
class EventChannel {
  /// Creates an [EventChannel] with the specified [name].
  ///
  /// The [codec] used will be [StandardMethodCodec], unless otherwise
  /// specified.
  ///
  /// Neither [name] nor [codec] may be null. The default [ServicesBinding.defaultBinaryMessenger]
  /// instance is used if [binaryMessenger] is null.
  const EventChannel(this.name, [this.codec = const StandardMethodCodec(), BinaryMessenger? binaryMessenger])
      : assert(name != null),
        assert(codec != null),
        _binaryMessenger = binaryMessenger;

  /// The logical channel on which communication happens, not null.
  final String name;

  /// The message codec used by this channel, not null.
  final MethodCodec codec;

  /// The messenger used by this channel to send platform messages, not null.
  BinaryMessenger get binaryMessenger => _binaryMessenger ?? ServicesBinding.instance!.defaultBinaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  /// Sets up a broadcast stream for receiving events on this channel.
  ///
  /// Returns a broadcast [Stream] which emits events to listeners as follows:
  ///
  /// * a decoded data event (possibly null) for each successful event
  ///   received from the platform plugin;
  /// * an error event containing a [PlatformException] for each error event
  ///   received from the platform plugin.
  ///
  /// Errors occurring during stream activation or deactivation are reported
  /// through the [FlutterError] facility. Stream activation happens only when
  /// stream listener count changes from 0 to 1. Stream deactivation happens
  /// only when stream listener count changes from 1 to 0.
  Stream<dynamic> receiveBroadcastStream([ dynamic arguments ]) {
    final MethodChannel methodChannel = MethodChannel(name, codec);
    late StreamController<dynamic> controller;
    controller = StreamController<dynamic>.broadcast(onListen: () async {
      binaryMessenger.setMessageHandler(name, (ByteData? reply) async {
        if (reply == null) {
          controller.close();
        } else {
          try {
            controller.add(codec.decodeEnvelope(reply));
          } on PlatformException catch (e) {
            controller.addError(e);
          }
        }
        return null;
      });
      try {
        await methodChannel.invokeMethod<void>('listen', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: ErrorDescription('while activating platform stream on channel $name'),
        ));
      }
    }, onCancel: () async {
      binaryMessenger.setMessageHandler(name, null);
      try {
        await methodChannel.invokeMethod<void>('cancel', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: ErrorDescription('while de-activating platform stream on channel $name'),
        ));
      }
    });
    return controller.stream;
  }
}
