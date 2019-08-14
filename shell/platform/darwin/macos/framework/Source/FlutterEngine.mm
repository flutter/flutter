// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"

#include <vector>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/embedder/embedder.h"

/**
 * Private interface declaration for FlutterEngine.
 */
@interface FlutterEngine () <FlutterBinaryMessenger>

/**
 * Called by the engine to make the context the engine should draw into current.
 */
- (bool)engineCallbackOnMakeCurrent;

/**
 * Called by the engine to clear the context the engine should draw into.
 */
- (bool)engineCallbackOnClearCurrent;

/**
 * Called by the engine when the context's buffers should be swapped.
 */
- (bool)engineCallbackOnPresent;

/**
 * Makes the resource context the current context.
 */
- (bool)engineCallbackOnMakeResourceCurrent;

/**
 * Handles a platform message from the engine.
 */
- (void)engineCallbackOnPlatformMessage:(const FlutterPlatformMessage*)message;

/**
 * Shuts the Flutter engine if it is running.
 */
- (void)shutDownEngine;

@end

#pragma mark -

/**
 * `FlutterPluginRegistrar` implementation handling a single plugin.
 */
@interface FlutterEngineRegistrar : NSObject <FlutterPluginRegistrar>
- (instancetype)initWithPlugin:(nonnull NSString*)pluginKey
                 flutterEngine:(nonnull FlutterEngine*)flutterEngine;
@end

@implementation FlutterEngineRegistrar {
  NSString* _pluginKey;
  FlutterEngine* _flutterEngine;
}

- (instancetype)initWithPlugin:(NSString*)pluginKey flutterEngine:(FlutterEngine*)flutterEngine {
  self = [super init];
  if (self) {
    _pluginKey = [pluginKey copy];
    _flutterEngine = flutterEngine;
  }
  return self;
}

#pragma mark - FlutterPluginRegistrar

- (id<FlutterBinaryMessenger>)messenger {
  return _flutterEngine.binaryMessenger;
}

- (NSView*)view {
  return _flutterEngine.viewController.view;
}

- (void)addMethodCallDelegate:(nonnull id<FlutterPlugin>)delegate
                      channel:(nonnull FlutterMethodChannel*)channel {
  [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    [delegate handleMethodCall:call result:result];
  }];
}

@end

// Callbacks provided to the engine. See the called methods for documentation.
#pragma mark - Static methods provided to engine configuration

static bool OnMakeCurrent(FlutterEngine* engine) {
  return [engine engineCallbackOnMakeCurrent];
}

static bool OnClearCurrent(FlutterEngine* engine) {
  return [engine engineCallbackOnClearCurrent];
}

static bool OnPresent(FlutterEngine* engine) {
  return [engine engineCallbackOnPresent];
}

static uint32_t OnFBO(FlutterEngine* engine) {
  // There is currently no case where a different FBO is used, so no need to forward.
  return 0;
}

static bool OnMakeResourceCurrent(FlutterEngine* engine) {
  return [engine engineCallbackOnMakeResourceCurrent];
}

static void OnPlatformMessage(const FlutterPlatformMessage* message, FlutterEngine* engine) {
  [engine engineCallbackOnPlatformMessage:message];
}

#pragma mark -

@implementation FlutterEngine {
  // The embedding-API-level engine object.
  FLUTTER_API_SYMBOL(FlutterEngine) _engine;

  // The project being run by this engine.
  FlutterDartProject* _project;

  // The context provided to the Flutter engine for resource loading.
  NSOpenGLContext* _resourceContext;

  // A mapping of channel names to the registered handlers for those channels.
  NSMutableDictionary<NSString*, FlutterBinaryMessageHandler>* _messageHandlers;

  // Whether the engine can continue running after the view controller is removed.
  BOOL _allowHeadlessExecution;
}

- (instancetype)initWithName:(NSString*)labelPrefix project:(FlutterDartProject*)project {
  return [self initWithName:labelPrefix project:project allowHeadlessExecution:YES];
}

- (instancetype)initWithName:(NSString*)labelPrefix
                     project:(FlutterDartProject*)project
      allowHeadlessExecution:(BOOL)allowHeadlessExecution {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");

  _project = project ?: [[FlutterDartProject alloc] init];
  _messageHandlers = [[NSMutableDictionary alloc] init];
  _allowHeadlessExecution = allowHeadlessExecution;

  return self;
}

- (void)dealloc {
  [self shutDownEngine];
}

- (BOOL)runWithEntrypoint:(NSString*)entrypoint {
  if (self.running) {
    return NO;
  }

  if (!_allowHeadlessExecution && !_viewController) {
    NSLog(@"Attempted to run an engine with no view controller without headless mode enabled.");
    return NO;
  }

  const FlutterRendererConfig rendererConfig = {
      .type = kOpenGL,
      .open_gl.struct_size = sizeof(FlutterOpenGLRendererConfig),
      .open_gl.make_current = (BoolCallback)OnMakeCurrent,
      .open_gl.clear_current = (BoolCallback)OnClearCurrent,
      .open_gl.present = (BoolCallback)OnPresent,
      .open_gl.fbo_callback = (UIntCallback)OnFBO,
      .open_gl.make_resource_current = (BoolCallback)OnMakeResourceCurrent,
  };

  // TODO(stuartmorgan): Move internal channel registration from FlutterViewController to here.

  FlutterProjectArgs flutterArguments = {};
  flutterArguments.struct_size = sizeof(FlutterProjectArgs);
  flutterArguments.assets_path = _project.assetsPath.UTF8String;
  flutterArguments.icu_data_path = _project.ICUDataPath.UTF8String;
  std::vector<const char*> arguments = _project.argv;
  flutterArguments.command_line_argc = static_cast<int>(arguments.size());
  flutterArguments.command_line_argv = &arguments[0];
  flutterArguments.platform_message_callback = (FlutterPlatformMessageCallback)OnPlatformMessage;
  flutterArguments.custom_dart_entrypoint = entrypoint.UTF8String;

  FlutterEngineResult result = FlutterEngineRun(
      FLUTTER_ENGINE_VERSION, &rendererConfig, &flutterArguments, (__bridge void*)(self), &_engine);
  if (result != kSuccess) {
    NSLog(@"Failed to start Flutter engine: error %d", result);
    return NO;
  }
  [self updateWindowMetrics];
  return YES;
}

- (void)setViewController:(FlutterViewController*)controller {
  _viewController = controller;
  if (!controller && !_allowHeadlessExecution) {
    [self shutDownEngine];
    _resourceContext = nil;
  }
  [self updateWindowMetrics];
}

- (id<FlutterBinaryMessenger>)binaryMessenger {
  // TODO(stuartmorgan): Switch to FlutterBinaryMessengerRelay to avoid plugins
  // keeping the engine alive.
  return self;
}

#pragma mark - Framework-internal methods

- (BOOL)running {
  return _engine != nullptr;
}

- (NSOpenGLContext*)resourceContext {
  if (!_resourceContext) {
    NSOpenGLPixelFormatAttribute attributes[] = {
        NSOpenGLPFAColorSize, 24, NSOpenGLPFAAlphaSize, 8, NSOpenGLPFADoubleBuffer, 0,
    };
    NSOpenGLPixelFormat* pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
    _resourceContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:nil];
  }
  return _resourceContext;
}

- (void)updateWindowMetrics {
  if (!_engine) {
    return;
  }
  NSView* view = _viewController.view;
  CGSize scaledSize = [view convertRectToBacking:view.bounds].size;
  double pixelRatio = view.bounds.size.width == 0 ? 1 : scaledSize.width / view.bounds.size.width;

  const FlutterWindowMetricsEvent event = {
      .struct_size = sizeof(event),
      .width = static_cast<size_t>(scaledSize.width),
      .height = static_cast<size_t>(scaledSize.height),
      .pixel_ratio = pixelRatio,
  };
  FlutterEngineSendWindowMetricsEvent(_engine, &event);
}

- (void)sendPointerEvent:(const FlutterPointerEvent&)event {
  FlutterEngineSendPointerEvent(_engine, &event, 1);
}

#pragma mark - Private methods

- (bool)engineCallbackOnMakeCurrent {
  if (!_viewController.flutterView) {
    return false;
  }
  [_viewController.flutterView makeCurrentContext];
  return true;
}

- (bool)engineCallbackOnClearCurrent {
  if (!_viewController.flutterView) {
    return false;
  }
  [NSOpenGLContext clearCurrentContext];
  return true;
}

- (bool)engineCallbackOnPresent {
  if (!_viewController.flutterView) {
    return false;
  }
  [_viewController.flutterView onPresent];
  return true;
}

- (bool)engineCallbackOnMakeResourceCurrent {
  if (!_viewController.flutterView) {
    return false;
  }
  [self.resourceContext makeCurrentContext];
  return true;
}

- (void)engineCallbackOnPlatformMessage:(const FlutterPlatformMessage*)message {
  NSData* messageData = [NSData dataWithBytesNoCopy:(void*)message->message
                                             length:message->message_size
                                       freeWhenDone:NO];
  NSString* channel = @(message->channel);
  __block const FlutterPlatformMessageResponseHandle* responseHandle = message->response_handle;

  FlutterBinaryReply binaryResponseHandler = ^(NSData* response) {
    if (responseHandle) {
      FlutterEngineSendPlatformMessageResponse(self->_engine, responseHandle,
                                               static_cast<const uint8_t*>(response.bytes),
                                               response.length);
      responseHandle = NULL;
    } else {
      NSLog(@"Error: Message responses can be sent only once. Ignoring duplicate response "
             "on channel '%@'.",
            channel);
    }
  };

  FlutterBinaryMessageHandler channelHandler = _messageHandlers[channel];
  if (channelHandler) {
    channelHandler(messageData, binaryResponseHandler);
  } else {
    binaryResponseHandler(nil);
  }
}

/**
 * Note: Called from dealloc. Should not use accessors or other methods.
 */
- (void)shutDownEngine {
  if (_engine) {
    FlutterEngineResult result = FlutterEngineShutdown(_engine);
    if (result != kSuccess) {
      NSLog(@"Failed to shut down Flutter engine: error %d", result);
    }
  }
  _engine = nullptr;
}

#pragma mark - FlutterBinaryMessenger

- (void)sendOnChannel:(nonnull NSString*)channel message:(nullable NSData*)message {
  [self sendOnChannel:channel message:message binaryReply:nil];
}

- (void)sendOnChannel:(NSString*)channel
              message:(NSData* _Nullable)message
          binaryReply:(FlutterBinaryReply _Nullable)callback {
  FlutterPlatformMessageResponseHandle* response_handle = nullptr;
  if (callback) {
    struct Captures {
      FlutterBinaryReply reply;
    };
    auto captures = std::make_unique<Captures>();
    captures->reply = callback;
    auto message_reply = [](const uint8_t* data, size_t data_size, void* user_data) {
      auto captures = reinterpret_cast<Captures*>(user_data);
      NSData* reply_data = nil;
      if (data != nullptr && data_size > 0) {
        reply_data = [NSData dataWithBytes:static_cast<const void*>(data) length:data_size];
      }
      captures->reply(reply_data);
      delete captures;
    };

    FlutterEngineResult create_result = FlutterPlatformMessageCreateResponseHandle(
        _engine, message_reply, captures.get(), &response_handle);
    if (create_result != kSuccess) {
      NSLog(@"Failed to create a FlutterPlatformMessageResponseHandle (%d)", create_result);
      return;
    }
    captures.release();
  }

  FlutterPlatformMessage platformMessage = {
      .struct_size = sizeof(FlutterPlatformMessage),
      .channel = [channel UTF8String],
      .message = static_cast<const uint8_t*>(message.bytes),
      .message_size = message.length,
      .response_handle = response_handle,
  };

  FlutterEngineResult message_result = FlutterEngineSendPlatformMessage(_engine, &platformMessage);
  if (message_result != kSuccess) {
    NSLog(@"Failed to send message to Flutter engine on channel '%@' (%d).", channel,
          message_result);
  }

  if (response_handle != nullptr) {
    FlutterEngineResult release_result =
        FlutterPlatformMessageReleaseResponseHandle(_engine, response_handle);
    if (release_result != kSuccess) {
      NSLog(@"Failed to release the response handle (%d).", release_result);
    };
  }
}

- (void)setMessageHandlerOnChannel:(nonnull NSString*)channel
              binaryMessageHandler:(nullable FlutterBinaryMessageHandler)handler {
  _messageHandlers[channel] = [handler copy];
}

#pragma mark - FlutterPluginRegistry

- (id<FlutterPluginRegistrar>)registrarForPlugin:(NSString*)pluginName {
  return [[FlutterEngineRegistrar alloc] initWithPlugin:pluginName flutterEngine:self];
}

@end
