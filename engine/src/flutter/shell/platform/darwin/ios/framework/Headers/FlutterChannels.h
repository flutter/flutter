// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLUTTERCHANNELS_H_
#define FLUTTER_FLUTTERCHANNELS_H_

#include "FlutterBinaryMessenger.h"
#include "FlutterCodecs.h"

NS_ASSUME_NONNULL_BEGIN
/**
 A strategy for handling a message reply.

 - Parameter reply: The reply.
 */
typedef void (^FlutterReplyHandler)(id _Nullable reply);

/**
 A strategy for handling a message.

 - Parameters:
   - message: The incoming message.
   - replyHandler: A call-back to asynchronously supply a reply to the message.
 */
typedef void (^FlutterMessageHandler)(id _Nullable message,
                                      FlutterReplyHandler replyHandler);

/**
 A channel for communicating with the Flutter side using asynchronous message
 passing.
 */
FLUTTER_EXPORT
@interface FlutterMessageChannel : NSObject
/**
 Creates a `FlutterMessageChannel` with the specified name and binary messenger.

 The channel name logically identifies the channel; identically named channels
 interfere with each other's communication.

 The binary messenger is a facility for sending raw, binary messages to the
 Flutter side. This protocol is implemented by `FlutterViewController`.

 The channel uses `FlutterStandardMessageCodec` to encode and decode messages.

 - Parameters:
   - name: The channel name.
   - messenger: The binary messenger.
 */
+ (instancetype)messageChannelWithName:(NSString*)name
                       binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

/**
 Creates a `FlutterMessageChannel` with the specified name, binary messenger,
 and message codec.

 The channel name logically identifies the channel; identically named channels
 interfere with each other's communication.

 The binary messenger is a facility for sending raw, binary messages to the
 Flutter side. This protocol is implemented by `FlutterViewController`.

 - Parameters:
   - name: The channel name.
   - messenger: The binary messenger.
   - codec: The message codec.
 */
+ (instancetype)messageChannelWithName:(NSString*)name
                       binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                                 codec:(NSObject<FlutterMessageCodec>*)codec;

/**
 Initializes a `FlutterMessageChannel` with the specified nane, binary messenger,
 and message codec.

 The channel name logically identifies the channel; identically named channels
 interfere with each other's communication.

 The binary messenger is a facility for sending raw, binary messages to the
 Flutter side. This protocol is implemented by `FlutterViewController`.

 - Parameters:
   - name: The channel name.
   - messenger: The binary messenger.
   - codec: The message codec.
 */
- (instancetype)initWithName:(NSString*)name
             binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                       codec:(NSObject<FlutterMessageCodec>*)codec;

/**
 Sends the specified message to the Flutter side, ignoring any reply.

 - Parameter message: The message. Must be supported by the codec of this channel.
 */
- (void)sendMessage:(id _Nullable)message;

/**
 Sends the specified message to the Flutter side, expecting an asynchronous reply.

 - Parameters:
   - message: The message. Must be supported by the codec of this channel.
   - handler: The reply handler.
 */
- (void)sendMessage:(id _Nullable)message replyHandler:(FlutterReplyHandler _Nullable)handler;

/**
 Registers a message handler with this channel.

 Replaces any existing handler. Use a `nil` handler for unregistering the
 existing handler.

 - Parameter handler: The message handler.
 */
- (void)setMessageHandler:(FlutterMessageHandler _Nullable)handler;
@end

/**
 A receiver of the result of a method call.

 - Parameter result: The result. Will be a `FlutterError` instance, if the method
   call resulted in an error on the Flutter side. Will be
   `FlutterMethodNotImplemented`, if the method called was not implemented on
   the Flutter side. All other values, including `nil` should be interpreted
   as successful results.
 */
typedef void (^FlutterResultReceiver)(id _Nullable result);

/**
 A strategy for handling method calls.

 - Parameters:
   - call: The incoming method call.
   - resultReceiver: A call-back to asynchronously supply the result of the call.
     Invoke the call-back with a `FlutterError` to indicate that the call failed.
     Invoke the call-back with `FlutterMethodNotImplemented` to indicate that the
     method was unknown. Any other values, including `nil` are interpreted as
     successful results.
 */
typedef void (^FlutterMethodCallHandler)(FlutterMethodCall* call,
                                         FlutterResultReceiver resultReceiver);

/**
 A constant used with `FlutterMethodCallHandler` to respond to the call of an
 unknown method.
 */
FLUTTER_EXPORT
extern NSObject const* FlutterMethodNotImplemented;


/**
 A channel for communicating with the Flutter side using invocation of
 asynchronous methods.
 */
FLUTTER_EXPORT
@interface FlutterMethodChannel : NSObject
/**
 Creates a `FlutterMethodChannel` with the specified name and binary messenger.

 The channel name logically identifies the channel; identically named channels
 interfere with each other's communication.

 The binary messenger is a facility for sending raw, binary messages to the
 Flutter side. This protocol is implemented by `FlutterViewController`.

 The channel uses `FlutterStandardMethodCodec` to encode and decode method calls
 and result envelopes.

 - Parameters:
   - name: The channel name.
   - messenger: The binary messenger.
 */
+ (instancetype)methodChannelWithName:(NSString*)name
                      binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

/**
 Creates a `FlutterMethodChannel` with the specified name, binary messenger, and
 method codec.

 The channel name logically identifies the channel; identically named channels
 interfere with each other's communication.

 The binary messenger is a facility for sending raw, binary messages to the
 Flutter side. This protocol is implemented by `FlutterViewController`.

 - Parameters:
   - name: The channel name.
   - messenger: The binary messenger.
   - codec: The method codec.
 */
+ (instancetype)methodChannelWithName:(NSString*)name
                      binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                             codec:(NSObject<FlutterMethodCodec>*)codec;

/**
 Initializes a `FlutterMethodChannel` with the specified name, binary messenger,
 and method codec.

 The channel name logically identifies the channel; identically named channels
 interfere with each other's communication.

 The binary messenger is a facility for sending raw, binary messages to the
 Flutter side. This protocol is implemented by `FlutterViewController`.

 - Parameters:
   - name: The channel name.
   - messenger: The binary messenger.
   - codec: The method codec.
 */
- (instancetype)initWithName:(NSString*)name
             binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                       codec:(NSObject<FlutterMethodCodec>*)codec;

/**
 Invokes the specified Flutter method with the specified arguments, expecting
 no results.

 - Parameters:
   - method: The name of the method to invoke.
   - arguments: The arguments. Must be a value supported by the codec of this
     channel.
 */
- (void)invokeMethod:(NSString*)method arguments:(id _Nullable)arguments;

/**
 Invokes the specified Flutter method with the specified arguments, expecting
 an asynchronous result.

 - Parameters:
   - method: The name of the method to invoke.
   - arguments: The arguments. Must be a value supported by the codec of this
     channel.
   - resultReceiver: A call-back for receipt of an asynchronous result.
     The result will be a `FlutterError` instance, if the method call resulted
     in an error on the Flutter side. Will be `FlutterMethodNotImplemented`, if
     the method called was not implemented on the Flutter side. Any other value,
     including `nil` should be interpreted as successful results.
 */
- (void)invokeMethod:(NSString*)method
           arguments:(id _Nullable)arguments
      resultReceiver:(FlutterResultReceiver _Nullable)resultReceiver;

/**
 Registers a handler for method calls from the Flutter side.

 Replaces any existing handler. Use a `nil` handler for unregistering the
 existing handler.

 - Parameter handler: The method call handler.
 */
- (void)setMethodCallHandler:(FlutterMethodCallHandler _Nullable)handler;
@end

/**
 A strategy for consuming events.

 - Parameter event: The event. Will be a `FlutterError` instance, if the
   event represents an error. Will be `FlutterEndOfEventStream`, if no more
   events will be emitted. All other values, including `nil` should be
   interpreted as success events.
 */
typedef void (^FlutterEventReceiver)(id _Nullable event);

/**
 A strategy for exposing an event stream to the Flutter side.
 */
FLUTTER_EXPORT
@protocol FlutterStreamHandler
/**
 Sets up an event stream and begin emitting events.

 Invoked when the first listener is registered with the Stream associated to
 this channel on the Flutter side.

 - Parameters:
   - arguments: Arguments for the stream.
   - eventReceiver: A call-back to asynchronously emit events. Invoke the
     call-back with a `FlutterError` to emit an error event. Invoke the
     call-back with `FlutterEndOfEventStream` to indicate that no more
     events will be emitted. Any other value, including `nil` are emitted as
     successful events.
 - Returns: A FlutterError instance, if setup fails.
 */
- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                   eventReceiver:(FlutterEventReceiver)eventReceiver;

/**
 Tears down an event stream.

 Invoked when the last listener is deregistered from the Stream associated to
 this channel on the Flutter side.

 - Parameter arguments: Arguments for the stream.
 - Returns: A FlutterError instance, if teardown fails.
 */
- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments;
@end

/**
 A constant used with `FlutterEventChannel` to indicate end of stream.
 */
FLUTTER_EXPORT
extern NSObject const* FlutterEndOfEventStream;

/**
 A channel for communicating with the Flutter side using event streams.
 */
FLUTTER_EXPORT
@interface FlutterEventChannel : NSObject
/**
 Creates a `FlutterEventChannel` with the specified name and binary messenger.

 The channel name logically identifies the channel; identically named channels
 interfere with each other's communication.

 The binary messenger is a facility for sending raw, binary messages to the
 Flutter side. This protocol is implemented by `FlutterViewController`.

 The channel uses `FlutterStandardMethodCodec` to decode stream setup and
 teardown requests, and to encode event envelopes.

 - Parameters:
   - name: The channel name.
   - messenger: The binary messenger.
   - codec: The method codec.
 */
+ (instancetype)eventChannelWithName:(NSString*)name
                     binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

/**
 Creates a `FlutterEventChannel` with the specified name, binary messenger,
 and method codec.

 The channel name logically identifies the channel; identically named channels
 interfere with each other's communication.

 The binary messenger is a facility for sending raw, binary messages to the
 Flutter side. This protocol is implemented by `FlutterViewController`.

 - Parameters:
   - name: The channel name.
   - messenger: The binary messenger.
   - codec: The method codec.
 */
+ (instancetype)eventChannelWithName:(NSString*)name
                     binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                               codec:(NSObject<FlutterMethodCodec>*)codec;

/**
 Initializes a `FlutterEventChannel` with the specified name, binary messenger,
 and method codec.

 The channel name logically identifies the channel; identically named channels
 interfere with each other's communication.

 The binary messenger is a facility for sending raw, binary messages to the
 Flutter side. This protocol is implemented by `FlutterViewController`.

 - Parameters:
   - name: The channel name.
   - messenger: The binary messenger.
   - codec: The method codec.
 */
- (instancetype)initWithName:(NSString*)name
             binaryMessenger:(NSObject<FlutterBinaryMessenger>*)messenger
                       codec:(NSObject<FlutterMethodCodec>*)codec;
/**
 Registers a handler for stream setup requests from the Flutter side.

 Replaces any existing handler. Use a `nil` handler for unregistering the
 existing handler.

 - Parameter handler: The stream handler.
 */
- (void)setStreamHandler:(NSObject<FlutterStreamHandler>* _Nullable)streamHandler;
@end
NS_ASSUME_NONNULL_END

#endif  // FLUTTER_FLUTTERCHANNELS_H_
