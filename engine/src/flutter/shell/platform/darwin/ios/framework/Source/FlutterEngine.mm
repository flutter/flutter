// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"

#include <memory>

#include "flutter/fml/message_loop.h"
#include "flutter/fml/platform/darwin/platform_version.h"
#include "flutter/fml/trace_event.h"
#include "flutter/runtime/ptrace_check.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/common/variable_refresh_rate_display.h"
#import "flutter/shell/platform/darwin/common/command_line.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterBinaryMessengerRelay.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartVMServicePublisher.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterIndirectScribbleDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSpellCheckPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextureRegistryRelay.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterUndoManagerDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterUndoManagerPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/connection_collection.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/platform_message_response_darwin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/profiler_metrics_ios.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#import "flutter/shell/platform/darwin/ios/rendering_api_selection.h"
#include "flutter/shell/profiling/sampling_profiler.h"

/// Inheriting ThreadConfigurer and use iOS platform thread API to configure the thread priorities
/// Using iOS platform thread API to configure thread priority
static void IOSPlatformThreadConfigSetter(const fml::Thread::ThreadConfig& config) {
  // set thread name
  fml::Thread::SetCurrentThreadName(config);

  // set thread priority
  switch (config.priority) {
    case fml::Thread::ThreadPriority::BACKGROUND: {
      [[NSThread currentThread] setThreadPriority:0];
      break;
    }
    case fml::Thread::ThreadPriority::NORMAL: {
      [[NSThread currentThread] setThreadPriority:0.5];
      break;
    }
    case fml::Thread::ThreadPriority::RASTER:
    case fml::Thread::ThreadPriority::DISPLAY: {
      [[NSThread currentThread] setThreadPriority:1.0];
      sched_param param;
      int policy;
      pthread_t thread = pthread_self();
      if (!pthread_getschedparam(thread, &policy, &param)) {
        param.sched_priority = 50;
        pthread_setschedparam(thread, policy, &param);
      }
      break;
    }
  }
}

#pragma mark - Public exported constants

NSString* const FlutterDefaultDartEntrypoint = nil;
NSString* const FlutterDefaultInitialRoute = nil;

#pragma mark - Internal constants

NSString* const kFlutterEngineWillDealloc = @"FlutterEngineWillDealloc";
NSString* const kFlutterKeyDataChannel = @"flutter/keydata";
static constexpr int kNumProfilerSamplesPerSec = 5;

@interface FlutterEngineRegistrar : NSObject <FlutterPluginRegistrar>
@property(nonatomic, assign) FlutterEngine* flutterEngine;
- (instancetype)initWithPlugin:(NSString*)pluginKey flutterEngine:(FlutterEngine*)flutterEngine;
@end

@interface FlutterEngine () <FlutterIndirectScribbleDelegate,
                             FlutterUndoManagerDelegate,
                             FlutterTextInputDelegate,
                             FlutterBinaryMessenger,
                             FlutterTextureRegistry>
// Maintains a dictionary of plugin names that have registered with the engine.  Used by
// FlutterEngineRegistrar to implement a FlutterPluginRegistrar.
@property(nonatomic, readonly) NSMutableDictionary* pluginPublications;
@property(nonatomic, readonly) NSMutableDictionary<NSString*, FlutterEngineRegistrar*>* registrars;

@property(nonatomic, readwrite, copy) NSString* isolateId;
@property(nonatomic, copy) NSString* initialRoute;
@property(nonatomic, retain) id<NSObject> flutterViewControllerWillDeallocObserver;

#pragma mark - Embedder API properties

@property(nonatomic, assign) BOOL enableEmbedderAPI;
// Function pointers for interacting with the embedder.h API.
@property(nonatomic) FlutterEngineProcTable& embedderAPI;
@end

@implementation FlutterEngine {
  fml::scoped_nsobject<FlutterDartProject> _dartProject;
  std::shared_ptr<flutter::ThreadHost> _threadHost;
  std::unique_ptr<flutter::Shell> _shell;
  NSString* _labelPrefix;
  std::unique_ptr<fml::WeakPtrFactory<FlutterEngine>> _weakFactory;

  fml::WeakPtr<FlutterViewController> _viewController;
  fml::scoped_nsobject<FlutterDartVMServicePublisher> _publisher;

  std::shared_ptr<flutter::FlutterPlatformViewsController> _platformViewsController;
  flutter::IOSRenderingAPI _renderingApi;
  std::shared_ptr<flutter::ProfilerMetricsIOS> _profiler_metrics;
  std::shared_ptr<flutter::SamplingProfiler> _profiler;

  // Channels
  fml::scoped_nsobject<FlutterPlatformPlugin> _platformPlugin;
  fml::scoped_nsobject<FlutterTextInputPlugin> _textInputPlugin;
  fml::scoped_nsobject<FlutterUndoManagerPlugin> _undoManagerPlugin;
  fml::scoped_nsobject<FlutterSpellCheckPlugin> _spellCheckPlugin;
  fml::scoped_nsobject<FlutterRestorationPlugin> _restorationPlugin;
  fml::scoped_nsobject<FlutterMethodChannel> _localizationChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _navigationChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _restorationChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _platformChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _platformViewsChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _textInputChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _undoManagerChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _scribbleChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _spellCheckChannel;
  fml::scoped_nsobject<FlutterBasicMessageChannel> _lifecycleChannel;
  fml::scoped_nsobject<FlutterBasicMessageChannel> _systemChannel;
  fml::scoped_nsobject<FlutterBasicMessageChannel> _settingsChannel;
  fml::scoped_nsobject<FlutterBasicMessageChannel> _keyEventChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _screenshotChannel;

  int64_t _nextTextureId;

  BOOL _allowHeadlessExecution;
  BOOL _restorationEnabled;
  FlutterBinaryMessengerRelay* _binaryMessenger;
  FlutterTextureRegistryRelay* _textureRegistry;
  std::unique_ptr<flutter::ConnectionCollection> _connections;
}

- (instancetype)init {
  return [self initWithName:@"FlutterEngine" project:nil allowHeadlessExecution:YES];
}

- (instancetype)initWithName:(NSString*)labelPrefix {
  return [self initWithName:labelPrefix project:nil allowHeadlessExecution:YES];
}

- (instancetype)initWithName:(NSString*)labelPrefix project:(FlutterDartProject*)project {
  return [self initWithName:labelPrefix project:project allowHeadlessExecution:YES];
}

- (instancetype)initWithName:(NSString*)labelPrefix
                     project:(FlutterDartProject*)project
      allowHeadlessExecution:(BOOL)allowHeadlessExecution {
  return [self initWithName:labelPrefix
                     project:project
      allowHeadlessExecution:allowHeadlessExecution
          restorationEnabled:NO];
}

- (instancetype)initWithName:(NSString*)labelPrefix
                     project:(FlutterDartProject*)project
      allowHeadlessExecution:(BOOL)allowHeadlessExecution
          restorationEnabled:(BOOL)restorationEnabled {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  NSAssert(labelPrefix, @"labelPrefix is required");

  _restorationEnabled = restorationEnabled;
  _allowHeadlessExecution = allowHeadlessExecution;
  _labelPrefix = [labelPrefix copy];

  _weakFactory = std::make_unique<fml::WeakPtrFactory<FlutterEngine>>(self);

  if (project == nil) {
    _dartProject.reset([[FlutterDartProject alloc] init]);
  } else {
    _dartProject.reset([project retain]);
  }

  _enableEmbedderAPI = _dartProject.get().settings.enable_embedder_api;
  if (_enableEmbedderAPI) {
    NSLog(@"============== iOS: enable_embedder_api is on ==============");
    _embedderAPI.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&_embedderAPI);
  }

  if (!EnableTracingIfNecessary([_dartProject.get() settings])) {
    NSLog(
        @"Cannot create a FlutterEngine instance in debug mode without Flutter tooling or "
        @"Xcode.\n\nTo launch in debug mode in iOS 14+, run flutter run from Flutter tools, run "
        @"from an IDE with a Flutter IDE plugin or run the iOS project from Xcode.\nAlternatively "
        @"profile and release mode apps can be launched from the home screen.");
    [self release];
    return nil;
  }

  _pluginPublications = [[NSMutableDictionary alloc] init];
  _registrars = [[NSMutableDictionary alloc] init];
  [self recreatePlatformViewController];

  _binaryMessenger = [[FlutterBinaryMessengerRelay alloc] initWithParent:self];
  _textureRegistry = [[FlutterTextureRegistryRelay alloc] initWithParent:self];
  _connections.reset(new flutter::ConnectionCollection());

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(onMemoryWarning:)
                 name:UIApplicationDidReceiveMemoryWarningNotification
               object:nil];

  [center addObserver:self
             selector:@selector(applicationWillEnterForeground:)
                 name:UIApplicationWillEnterForegroundNotification
               object:nil];

  [center addObserver:self
             selector:@selector(applicationDidEnterBackground:)
                 name:UIApplicationDidEnterBackgroundNotification
               object:nil];

  [center addObserver:self
             selector:@selector(onLocaleUpdated:)
                 name:NSCurrentLocaleDidChangeNotification
               object:nil];

  return self;
}

- (void)recreatePlatformViewController {
  _renderingApi = flutter::GetRenderingAPIForProcess(FlutterView.forceSoftwareRendering);
  _platformViewsController.reset(new flutter::FlutterPlatformViewsController());
}

- (flutter::IOSRenderingAPI)platformViewsRenderingAPI {
  return _renderingApi;
}

- (void)dealloc {
  /// Notify plugins of dealloc.  This should happen first in dealloc since the
  /// plugins may be talking to things like the binaryMessenger.
  [_pluginPublications enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL* stop) {
    if ([object respondsToSelector:@selector(detachFromEngineForRegistrar:)]) {
      NSObject<FlutterPluginRegistrar>* registrar = self.registrars[key];
      [object detachFromEngineForRegistrar:registrar];
    }
  }];

  [[NSNotificationCenter defaultCenter] postNotificationName:kFlutterEngineWillDealloc
                                                      object:self
                                                    userInfo:nil];

  // It will be destroyed and invalidate its weak pointers
  // before any other members are destroyed.
  _weakFactory.reset();

  /// nil out weak references.
  [_registrars
      enumerateKeysAndObjectsUsingBlock:^(id key, FlutterEngineRegistrar* registrar, BOOL* stop) {
        registrar.flutterEngine = nil;
      }];

  [_labelPrefix release];
  [_initialRoute release];
  [_pluginPublications release];
  [_registrars release];
  _binaryMessenger.parent = nil;
  _textureRegistry.parent = nil;
  [_binaryMessenger release];
  [_textureRegistry release];
  _textureRegistry = nil;
  [_isolateId release];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  if (_flutterViewControllerWillDeallocObserver) {
    [center removeObserver:_flutterViewControllerWillDeallocObserver];
    [_flutterViewControllerWillDeallocObserver release];
  }
  [center removeObserver:self];

  [super dealloc];
}

- (flutter::Shell&)shell {
  FML_DCHECK(_shell);
  return *_shell;
}

- (fml::WeakPtr<FlutterEngine>)getWeakPtr {
  return _weakFactory->GetWeakPtr();
}

- (void)updateViewportMetrics:(flutter::ViewportMetrics)viewportMetrics {
  if (!self.platformView) {
    return;
  }
  self.platformView->SetViewportMetrics(viewportMetrics);
}

- (void)dispatchPointerDataPacket:(std::unique_ptr<flutter::PointerDataPacket>)packet {
  if (!self.platformView) {
    return;
  }
  self.platformView->DispatchPointerDataPacket(std::move(packet));
}

- (fml::WeakPtr<flutter::PlatformView>)platformView {
  FML_DCHECK(_shell);
  return _shell->GetPlatformView();
}

- (flutter::PlatformViewIOS*)iosPlatformView {
  FML_DCHECK(_shell);
  return static_cast<flutter::PlatformViewIOS*>(_shell->GetPlatformView().get());
}

- (fml::RefPtr<fml::TaskRunner>)platformTaskRunner {
  FML_DCHECK(_shell);
  return _shell->GetTaskRunners().GetPlatformTaskRunner();
}

- (fml::RefPtr<fml::TaskRunner>)RasterTaskRunner {
  FML_DCHECK(_shell);
  return _shell->GetTaskRunners().GetRasterTaskRunner();
}

- (void)sendKeyEvent:(const FlutterKeyEvent&)event
            callback:(FlutterKeyEventCallback)callback
            userData:(void*)userData API_AVAILABLE(ios(13.4)) {
  if (@available(iOS 13.4, *)) {
  } else {
    return;
  }
  if (!self.platformView) {
    return;
  }
  const char* character = event.character;

  flutter::KeyData key_data;
  key_data.Clear();
  key_data.timestamp = (uint64_t)event.timestamp;
  switch (event.type) {
    case kFlutterKeyEventTypeUp:
      key_data.type = flutter::KeyEventType::kUp;
      break;
    case kFlutterKeyEventTypeDown:
      key_data.type = flutter::KeyEventType::kDown;
      break;
    case kFlutterKeyEventTypeRepeat:
      key_data.type = flutter::KeyEventType::kRepeat;
      break;
  }
  key_data.physical = event.physical;
  key_data.logical = event.logical;
  key_data.synthesized = event.synthesized;

  auto packet = std::make_unique<flutter::KeyDataPacket>(key_data, character);
  NSData* message = [NSData dataWithBytes:packet->data().data() length:packet->data().size()];

  auto response = ^(NSData* reply) {
    if (callback == nullptr) {
      return;
    }
    BOOL handled = FALSE;
    if (reply.length == 1 && *reinterpret_cast<const uint8_t*>(reply.bytes) == 1) {
      handled = TRUE;
    }
    callback(handled, userData);
  };

  [self sendOnChannel:kFlutterKeyDataChannel message:message binaryReply:response];
}

- (void)ensureSemanticsEnabled {
  self.iosPlatformView->SetSemanticsEnabled(true);
}

- (void)setViewController:(FlutterViewController*)viewController {
  FML_DCHECK(self.iosPlatformView);
  _viewController =
      viewController ? [viewController getWeakPtr] : fml::WeakPtr<FlutterViewController>();
  self.iosPlatformView->SetOwnerViewController(_viewController);
  [self maybeSetupPlatformViewChannels];
  _textInputPlugin.get().viewController = viewController;
  _undoManagerPlugin.get().viewController = viewController;

  if (viewController) {
    __block FlutterEngine* blockSelf = self;
    self.flutterViewControllerWillDeallocObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:FlutterViewControllerWillDealloc
                                                          object:viewController
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note) {
                                                        [blockSelf notifyViewControllerDeallocated];
                                                      }];
  } else {
    self.flutterViewControllerWillDeallocObserver = nil;
    [self notifyLowMemory];
  }
}

- (void)attachView {
  self.iosPlatformView->attachView();
}

- (void)setFlutterViewControllerWillDeallocObserver:(id<NSObject>)observer {
  if (observer != _flutterViewControllerWillDeallocObserver) {
    if (_flutterViewControllerWillDeallocObserver) {
      [[NSNotificationCenter defaultCenter]
          removeObserver:_flutterViewControllerWillDeallocObserver];
      [_flutterViewControllerWillDeallocObserver release];
    }
    _flutterViewControllerWillDeallocObserver = [observer retain];
  }
}

- (void)notifyViewControllerDeallocated {
  [[self lifecycleChannel] sendMessage:@"AppLifecycleState.detached"];
  _textInputPlugin.get().viewController = nil;
  _undoManagerPlugin.get().viewController = nil;
  if (!_allowHeadlessExecution) {
    [self destroyContext];
  } else if (_shell) {
    flutter::PlatformViewIOS* platform_view = [self iosPlatformView];
    if (platform_view) {
      platform_view->SetOwnerViewController({});
    }
  }
  [_textInputPlugin.get() resetViewResponder];
  _viewController.reset();
}

- (void)destroyContext {
  [self resetChannels];
  self.isolateId = nil;
  _shell.reset();
  _profiler.reset();
  _threadHost.reset();
  _platformViewsController.reset();
}

- (FlutterViewController*)viewController {
  if (!_viewController) {
    return nil;
  }
  return _viewController.get();
}

- (FlutterPlatformPlugin*)platformPlugin {
  return _platformPlugin.get();
}
- (std::shared_ptr<flutter::FlutterPlatformViewsController>&)platformViewsController {
  return _platformViewsController;
}
- (FlutterTextInputPlugin*)textInputPlugin {
  return _textInputPlugin.get();
}
- (FlutterUndoManagerPlugin*)undoManagerPlugin {
  return _undoManagerPlugin.get();
}
- (FlutterRestorationPlugin*)restorationPlugin {
  return _restorationPlugin.get();
}
- (FlutterMethodChannel*)localizationChannel {
  return _localizationChannel.get();
}
- (FlutterMethodChannel*)navigationChannel {
  return _navigationChannel.get();
}
- (FlutterMethodChannel*)restorationChannel {
  return _restorationChannel.get();
}
- (FlutterMethodChannel*)platformChannel {
  return _platformChannel.get();
}
- (FlutterMethodChannel*)textInputChannel {
  return _textInputChannel.get();
}
- (FlutterMethodChannel*)undoManagerChannel {
  return _undoManagerChannel.get();
}
- (FlutterMethodChannel*)scribbleChannel {
  return _scribbleChannel.get();
}
- (FlutterMethodChannel*)spellCheckChannel {
  return _spellCheckChannel.get();
}
- (FlutterBasicMessageChannel*)lifecycleChannel {
  return _lifecycleChannel.get();
}
- (FlutterBasicMessageChannel*)systemChannel {
  return _systemChannel.get();
}
- (FlutterBasicMessageChannel*)settingsChannel {
  return _settingsChannel.get();
}
- (FlutterBasicMessageChannel*)keyEventChannel {
  return _keyEventChannel.get();
}

- (NSURL*)observatoryUrl {
  return [_publisher.get() url];
}

- (NSURL*)vmServiceUrl {
  return [_publisher.get() url];
}

- (void)resetChannels {
  _localizationChannel.reset();
  _navigationChannel.reset();
  _restorationChannel.reset();
  _platformChannel.reset();
  _platformViewsChannel.reset();
  _textInputChannel.reset();
  _undoManagerChannel.reset();
  _scribbleChannel.reset();
  _lifecycleChannel.reset();
  _systemChannel.reset();
  _settingsChannel.reset();
  _keyEventChannel.reset();
  _spellCheckChannel.reset();
}

- (void)startProfiler {
  FML_DCHECK(!_threadHost->name_prefix.empty());
  _profiler_metrics = std::make_shared<flutter::ProfilerMetricsIOS>();
  _profiler = std::make_shared<flutter::SamplingProfiler>(
      _threadHost->name_prefix.c_str(), _threadHost->profiler_thread->GetTaskRunner(),
      [self]() { return self->_profiler_metrics->GenerateSample(); }, kNumProfilerSamplesPerSec);
  _profiler->Start();
}

// If you add a channel, be sure to also update `resetChannels`.
// Channels get a reference to the engine, and therefore need manual
// cleanup for proper collection.
- (void)setupChannels {
  // This will be invoked once the shell is done setting up and the isolate ID
  // for the UI isolate is available.
  fml::WeakPtr<FlutterEngine> weakSelf = [self getWeakPtr];
  [_binaryMessenger setMessageHandlerOnChannel:@"flutter/isolate"
                          binaryMessageHandler:^(NSData* message, FlutterBinaryReply reply) {
                            if (weakSelf) {
                              weakSelf.get().isolateId =
                                  [[FlutterStringCodec sharedInstance] decode:message];
                            }
                          }];

  _localizationChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/localization"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  _navigationChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/navigation"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  if ([_initialRoute length] > 0) {
    // Flutter isn't ready to receive this method call yet but the channel buffer will cache this.
    [_navigationChannel invokeMethod:@"setInitialRoute" arguments:_initialRoute];
    [_initialRoute release];
    _initialRoute = nil;
  }

  _restorationChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/restoration"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterStandardMethodCodec sharedInstance]]);

  _platformChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/platform"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  _platformViewsChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/platform_views"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterStandardMethodCodec sharedInstance]]);

  _textInputChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/textinput"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  _undoManagerChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/undomanager"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  _scribbleChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/scribble"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterJSONMethodCodec sharedInstance]]);

  _spellCheckChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/spellcheck"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterStandardMethodCodec sharedInstance]]);

  _lifecycleChannel.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/lifecycle"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterStringCodec sharedInstance]]);

  _systemChannel.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/system"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterJSONMessageCodec sharedInstance]]);

  _settingsChannel.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/settings"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterJSONMessageCodec sharedInstance]]);

  _keyEventChannel.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/keyevent"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterJSONMessageCodec sharedInstance]]);

  FlutterTextInputPlugin* textInputPlugin = [[FlutterTextInputPlugin alloc] initWithDelegate:self];
  _textInputPlugin.reset(textInputPlugin);
  textInputPlugin.indirectScribbleDelegate = self;
  [textInputPlugin setupIndirectScribbleInteraction:self.viewController];

  FlutterUndoManagerPlugin* undoManagerPlugin =
      [[FlutterUndoManagerPlugin alloc] initWithDelegate:self];
  _undoManagerPlugin.reset(undoManagerPlugin);

  _platformPlugin.reset([[FlutterPlatformPlugin alloc] initWithEngine:[self getWeakPtr]]);

  _restorationPlugin.reset([[FlutterRestorationPlugin alloc]
         initWithChannel:_restorationChannel.get()
      restorationEnabled:_restorationEnabled]);
  _spellCheckPlugin.reset([[FlutterSpellCheckPlugin alloc] init]);

  _screenshotChannel.reset([[FlutterMethodChannel alloc]
         initWithName:@"flutter/screenshot"
      binaryMessenger:self.binaryMessenger
                codec:[FlutterStandardMethodCodec sharedInstance]]);

  [_screenshotChannel.get()
      setMethodCallHandler:^(FlutterMethodCall* _Nonnull call, FlutterResult _Nonnull result) {
        if (!(weakSelf.get() && weakSelf.get()->_shell && weakSelf.get()->_shell->IsSetup())) {
          return result([FlutterError
              errorWithCode:@"invalid_state"
                    message:@"Requesting screenshot while engine is not running."
                    details:nil]);
        }
        flutter::Rasterizer::Screenshot screenshot =
            [weakSelf.get() screenshot:flutter::Rasterizer::ScreenshotType::SurfaceData
                          base64Encode:NO];
        if (!screenshot.data) {
          return result([FlutterError errorWithCode:@"failure"
                                            message:@"Unable to get screenshot."
                                            details:nil]);
        }
        // TODO(gaaclarke): Find way to eliminate this data copy.
        NSData* data = [NSData dataWithBytes:screenshot.data->writable_data()
                                      length:screenshot.data->size()];
        NSString* format = [NSString stringWithCString:screenshot.format.c_str()];
        NSNumber* width = @(screenshot.frame_size.fWidth);
        NSNumber* height = @(screenshot.frame_size.fHeight);
        return result(@[ width, height, format, data ]);
      }];
}

- (void)maybeSetupPlatformViewChannels {
  if (_shell && self.shell.IsSetup()) {
    FlutterPlatformPlugin* platformPlugin = _platformPlugin.get();
    [_platformChannel.get() setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      [platformPlugin handleMethodCall:call result:result];
    }];

    fml::WeakPtr<FlutterEngine> weakSelf = [self getWeakPtr];
    [_platformViewsChannel.get()
        setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
          if (weakSelf) {
            weakSelf.get().platformViewsController->OnMethodCall(call, result);
          }
        }];

    FlutterTextInputPlugin* textInputPlugin = _textInputPlugin.get();
    [_textInputChannel.get() setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      [textInputPlugin handleMethodCall:call result:result];
    }];

    FlutterUndoManagerPlugin* undoManagerPlugin = _undoManagerPlugin.get();
    [_undoManagerChannel.get()
        setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
          [undoManagerPlugin handleMethodCall:call result:result];
        }];

    FlutterSpellCheckPlugin* spellCheckPlugin = _spellCheckPlugin.get();
    [_spellCheckChannel.get()
        setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
          [spellCheckPlugin handleMethodCall:call result:result];
        }];
  }
}

- (flutter::Rasterizer::Screenshot)screenshot:(flutter::Rasterizer::ScreenshotType)type
                                 base64Encode:(bool)base64Encode {
  return self.shell.Screenshot(type, base64Encode);
}

- (void)launchEngine:(NSString*)entrypoint
          libraryURI:(NSString*)libraryOrNil
      entrypointArgs:(NSArray<NSString*>*)entrypointArgs {
  // Launch the Dart application with the inferred run configuration.
  self.shell.RunEngine([_dartProject.get() runConfigurationForEntrypoint:entrypoint
                                                            libraryOrNil:libraryOrNil
                                                          entrypointArgs:entrypointArgs]);
}

- (void)setupShell:(std::unique_ptr<flutter::Shell>)shell
    withVMServicePublication:(BOOL)doesVMServicePublication {
  _shell = std::move(shell);
  [self setupChannels];
  [self onLocaleUpdated:nil];
  [self initializeDisplays];
  _publisher.reset([[FlutterDartVMServicePublisher alloc]
      initWithEnableVMServicePublication:doesVMServicePublication]);
  [self maybeSetupPlatformViewChannels];
  _shell->SetGpuAvailability(_isGpuDisabled ? flutter::GpuAvailability::kUnavailable
                                            : flutter::GpuAvailability::kAvailable);
}

+ (BOOL)isProfilerEnabled {
  bool profilerEnabled = false;
#if (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG) || \
    (FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE)
  profilerEnabled = true;
#endif
  return profilerEnabled;
}

+ (NSString*)generateThreadLabel:(NSString*)labelPrefix {
  static size_t s_shellCount = 0;
  return [NSString stringWithFormat:@"%@.%zu", labelPrefix, ++s_shellCount];
}

+ (flutter::ThreadHost)makeThreadHost:(NSString*)threadLabel {
  // The current thread will be used as the platform thread. Ensure that the message loop is
  // initialized.
  fml::MessageLoop::EnsureInitializedForCurrentThread();

  uint32_t threadHostType = flutter::ThreadHost::Type::UI | flutter::ThreadHost::Type::RASTER |
                            flutter::ThreadHost::Type::IO;

  if ([FlutterEngine isProfilerEnabled]) {
    threadHostType = threadHostType | flutter::ThreadHost::Type::Profiler;
  }

  flutter::ThreadHost::ThreadHostConfig host_config(threadLabel.UTF8String, threadHostType,
                                                    IOSPlatformThreadConfigSetter);

  host_config.ui_config =
      fml::Thread::ThreadConfig(flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
                                    flutter::ThreadHost::Type::UI, threadLabel.UTF8String),
                                fml::Thread::ThreadPriority::DISPLAY);

  host_config.raster_config =
      fml::Thread::ThreadConfig(flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
                                    flutter::ThreadHost::Type::RASTER, threadLabel.UTF8String),
                                fml::Thread::ThreadPriority::RASTER);

  host_config.io_config =
      fml::Thread::ThreadConfig(flutter::ThreadHost::ThreadHostConfig::MakeThreadName(
                                    flutter::ThreadHost::Type::IO, threadLabel.UTF8String),
                                fml::Thread::ThreadPriority::NORMAL);

  return (flutter::ThreadHost){host_config};
}

static void SetEntryPoint(flutter::Settings* settings, NSString* entrypoint, NSString* libraryURI) {
  if (libraryURI) {
    FML_DCHECK(entrypoint) << "Must specify entrypoint if specifying library";
    settings->advisory_script_entrypoint = entrypoint.UTF8String;
    settings->advisory_script_uri = libraryURI.UTF8String;
  } else if (entrypoint) {
    settings->advisory_script_entrypoint = entrypoint.UTF8String;
    settings->advisory_script_uri = std::string("main.dart");
  } else {
    settings->advisory_script_entrypoint = std::string("main");
    settings->advisory_script_uri = std::string("main.dart");
  }
}

- (BOOL)createShell:(NSString*)entrypoint
         libraryURI:(NSString*)libraryURI
       initialRoute:(NSString*)initialRoute {
  if (_shell != nullptr) {
    FML_LOG(WARNING) << "This FlutterEngine was already invoked.";
    return NO;
  }

  self.initialRoute = initialRoute;

  auto settings = [_dartProject.get() settings];
  if (initialRoute != nil) {
    self.initialRoute = initialRoute;
  } else if (settings.route.empty() == false) {
    self.initialRoute = [NSString stringWithCString:settings.route.c_str()
                                           encoding:NSUTF8StringEncoding];
  }

  FlutterView.forceSoftwareRendering = settings.enable_software_rendering;

  auto platformData = [_dartProject.get() defaultPlatformData];

  SetEntryPoint(&settings, entrypoint, libraryURI);

  NSString* threadLabel = [FlutterEngine generateThreadLabel:_labelPrefix];
  _threadHost = std::make_shared<flutter::ThreadHost>();
  *_threadHost = [FlutterEngine makeThreadHost:threadLabel];

  // Lambda captures by pointers to ObjC objects are fine here because the
  // create call is synchronous.
  flutter::Shell::CreateCallback<flutter::PlatformView> on_create_platform_view =
      [self](flutter::Shell& shell) {
        [self recreatePlatformViewController];
        return std::make_unique<flutter::PlatformViewIOS>(
            shell, self->_renderingApi, self->_platformViewsController, shell.GetTaskRunners());
      };

  flutter::Shell::CreateCallback<flutter::Rasterizer> on_create_rasterizer =
      [](flutter::Shell& shell) { return std::make_unique<flutter::Rasterizer>(shell); };

  flutter::TaskRunners task_runners(threadLabel.UTF8String,                          // label
                                    fml::MessageLoop::GetCurrent().GetTaskRunner(),  // platform
                                    _threadHost->raster_thread->GetTaskRunner(),     // raster
                                    _threadHost->ui_thread->GetTaskRunner(),         // ui
                                    _threadHost->io_thread->GetTaskRunner()          // io
  );

  _isGpuDisabled =
      [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
  // Create the shell. This is a blocking operation.
  std::unique_ptr<flutter::Shell> shell = flutter::Shell::Create(
      /*platform_data=*/platformData,
      /*task_runners=*/task_runners,
      /*settings=*/settings,
      /*on_create_platform_view=*/on_create_platform_view,
      /*on_create_rasterizer=*/on_create_rasterizer,
      /*is_gpu_disabled=*/_isGpuDisabled);

  if (shell == nullptr) {
    FML_LOG(ERROR) << "Could not start a shell FlutterEngine with entrypoint: "
                   << entrypoint.UTF8String;
  } else {
    [self setupShell:std::move(shell)
        withVMServicePublication:settings.enable_vm_service_publication];
    if ([FlutterEngine isProfilerEnabled]) {
      [self startProfiler];
    }
  }

  return _shell != nullptr;
}

- (void)initializeDisplays {
  auto vsync_waiter = std::shared_ptr<flutter::VsyncWaiter>(_shell->GetVsyncWaiter().lock());
  auto vsync_waiter_ios = std::static_pointer_cast<flutter::VsyncWaiterIOS>(vsync_waiter);
  std::vector<std::unique_ptr<flutter::Display>> displays;
  displays.push_back(std::make_unique<flutter::VariableRefreshRateDisplay>(vsync_waiter_ios));
  _shell->OnDisplayUpdates(flutter::DisplayUpdateType::kStartup, std::move(displays));
}

- (BOOL)run {
  return [self runWithEntrypoint:FlutterDefaultDartEntrypoint
                      libraryURI:nil
                    initialRoute:FlutterDefaultInitialRoute];
}

- (BOOL)runWithEntrypoint:(NSString*)entrypoint libraryURI:(NSString*)libraryURI {
  return [self runWithEntrypoint:entrypoint
                      libraryURI:libraryURI
                    initialRoute:FlutterDefaultInitialRoute];
}

- (BOOL)runWithEntrypoint:(NSString*)entrypoint {
  return [self runWithEntrypoint:entrypoint libraryURI:nil initialRoute:FlutterDefaultInitialRoute];
}

- (BOOL)runWithEntrypoint:(NSString*)entrypoint initialRoute:(NSString*)initialRoute {
  return [self runWithEntrypoint:entrypoint libraryURI:nil initialRoute:initialRoute];
}

- (BOOL)runWithEntrypoint:(NSString*)entrypoint
               libraryURI:(NSString*)libraryURI
             initialRoute:(NSString*)initialRoute {
  return [self runWithEntrypoint:entrypoint
                      libraryURI:libraryURI
                    initialRoute:initialRoute
                  entrypointArgs:nil];
}

- (BOOL)runWithEntrypoint:(NSString*)entrypoint
               libraryURI:(NSString*)libraryURI
             initialRoute:(NSString*)initialRoute
           entrypointArgs:(NSArray<NSString*>*)entrypointArgs {
  if ([self createShell:entrypoint libraryURI:libraryURI initialRoute:initialRoute]) {
    [self launchEngine:entrypoint libraryURI:libraryURI entrypointArgs:entrypointArgs];
  }

  return _shell != nullptr;
}

- (void)notifyLowMemory {
  if (_shell) {
    _shell->NotifyLowMemoryWarning();
  }
  [_systemChannel sendMessage:@{@"type" : @"memoryPressure"}];
}

#pragma mark - Text input delegate

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView
         updateEditingClient:(int)client
                   withState:(NSDictionary*)state {
  [_textInputChannel.get() invokeMethod:@"TextInputClient.updateEditingState"
                              arguments:@[ @(client), state ]];
}

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView
         updateEditingClient:(int)client
                   withState:(NSDictionary*)state
                     withTag:(NSString*)tag {
  [_textInputChannel.get() invokeMethod:@"TextInputClient.updateEditingStateWithTag"
                              arguments:@[ @(client), @{tag : state} ]];
}

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView
         updateEditingClient:(int)client
                   withDelta:(NSDictionary*)delta {
  [_textInputChannel.get() invokeMethod:@"TextInputClient.updateEditingStateWithDeltas"
                              arguments:@[ @(client), delta ]];
}

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView
        updateFloatingCursor:(FlutterFloatingCursorDragState)state
                  withClient:(int)client
                withPosition:(NSDictionary*)position {
  NSString* stateString;
  switch (state) {
    case FlutterFloatingCursorDragStateStart:
      stateString = @"FloatingCursorDragState.start";
      break;
    case FlutterFloatingCursorDragStateUpdate:
      stateString = @"FloatingCursorDragState.update";
      break;
    case FlutterFloatingCursorDragStateEnd:
      stateString = @"FloatingCursorDragState.end";
      break;
  }
  [_textInputChannel.get() invokeMethod:@"TextInputClient.updateFloatingCursor"
                              arguments:@[ @(client), stateString, position ]];
}

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView
               performAction:(FlutterTextInputAction)action
                  withClient:(int)client {
  NSString* actionString;
  switch (action) {
    case FlutterTextInputActionUnspecified:
      // Where did the term "unspecified" come from? iOS has a "default" and Android
      // has "unspecified." These 2 terms seem to mean the same thing but we need
      // to pick just one. "unspecified" was chosen because "default" is often a
      // reserved word in languages with switch statements (dart, java, etc).
      actionString = @"TextInputAction.unspecified";
      break;
    case FlutterTextInputActionDone:
      actionString = @"TextInputAction.done";
      break;
    case FlutterTextInputActionGo:
      actionString = @"TextInputAction.go";
      break;
    case FlutterTextInputActionSend:
      actionString = @"TextInputAction.send";
      break;
    case FlutterTextInputActionSearch:
      actionString = @"TextInputAction.search";
      break;
    case FlutterTextInputActionNext:
      actionString = @"TextInputAction.next";
      break;
    case FlutterTextInputActionContinue:
      actionString = @"TextInputAction.continue";
      break;
    case FlutterTextInputActionJoin:
      actionString = @"TextInputAction.join";
      break;
    case FlutterTextInputActionRoute:
      actionString = @"TextInputAction.route";
      break;
    case FlutterTextInputActionEmergencyCall:
      actionString = @"TextInputAction.emergencyCall";
      break;
    case FlutterTextInputActionNewline:
      actionString = @"TextInputAction.newline";
      break;
  }
  [_textInputChannel.get() invokeMethod:@"TextInputClient.performAction"
                              arguments:@[ @(client), actionString ]];
}

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView
    showAutocorrectionPromptRectForStart:(NSUInteger)start
                                     end:(NSUInteger)end
                              withClient:(int)client {
  [_textInputChannel.get() invokeMethod:@"TextInputClient.showAutocorrectionPromptRect"
                              arguments:@[ @(client), @(start), @(end) ]];
}

#pragma mark - FlutterViewEngineDelegate

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView showToolbar:(int)client {
  // TODO(justinmc): Switch from the TextInputClient to Scribble channel when
  // the framework has finished transitioning to the Scribble channel.
  // https://github.com/flutter/flutter/pull/115296
  [_textInputChannel.get() invokeMethod:@"TextInputClient.showToolbar" arguments:@[ @(client) ]];
}

- (void)flutterTextInputPlugin:(FlutterTextInputPlugin*)textInputPlugin
                  focusElement:(UIScribbleElementIdentifier)elementIdentifier
                       atPoint:(CGPoint)referencePoint
                        result:(FlutterResult)callback {
  // TODO(justinmc): Switch from the TextInputClient to Scribble channel when
  // the framework has finished transitioning to the Scribble channel.
  // https://github.com/flutter/flutter/pull/115296
  [_textInputChannel.get()
      invokeMethod:@"TextInputClient.focusElement"
         arguments:@[ elementIdentifier, @(referencePoint.x), @(referencePoint.y) ]
            result:callback];
}

- (void)flutterTextInputPlugin:(FlutterTextInputPlugin*)textInputPlugin
         requestElementsInRect:(CGRect)rect
                        result:(FlutterResult)callback {
  // TODO(justinmc): Switch from the TextInputClient to Scribble channel when
  // the framework has finished transitioning to the Scribble channel.
  // https://github.com/flutter/flutter/pull/115296
  [_textInputChannel.get()
      invokeMethod:@"TextInputClient.requestElementsInRect"
         arguments:@[ @(rect.origin.x), @(rect.origin.y), @(rect.size.width), @(rect.size.height) ]
            result:callback];
}

- (void)flutterTextInputViewScribbleInteractionBegan:(FlutterTextInputView*)textInputView {
  // TODO(justinmc): Switch from the TextInputClient to Scribble channel when
  // the framework has finished transitioning to the Scribble channel.
  // https://github.com/flutter/flutter/pull/115296
  [_textInputChannel.get() invokeMethod:@"TextInputClient.scribbleInteractionBegan" arguments:nil];
}

- (void)flutterTextInputViewScribbleInteractionFinished:(FlutterTextInputView*)textInputView {
  // TODO(justinmc): Switch from the TextInputClient to Scribble channel when
  // the framework has finished transitioning to the Scribble channel.
  // https://github.com/flutter/flutter/pull/115296
  [_textInputChannel.get() invokeMethod:@"TextInputClient.scribbleInteractionFinished"
                              arguments:nil];
}

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView
    insertTextPlaceholderWithSize:(CGSize)size
                       withClient:(int)client {
  // TODO(justinmc): Switch from the TextInputClient to Scribble channel when
  // the framework has finished transitioning to the Scribble channel.
  // https://github.com/flutter/flutter/pull/115296
  [_textInputChannel.get() invokeMethod:@"TextInputClient.insertTextPlaceholder"
                              arguments:@[ @(client), @(size.width), @(size.height) ]];
}

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView
       removeTextPlaceholder:(int)client {
  // TODO(justinmc): Switch from the TextInputClient to Scribble channel when
  // the framework has finished transitioning to the Scribble channel.
  // https://github.com/flutter/flutter/pull/115296
  [_textInputChannel.get() invokeMethod:@"TextInputClient.removeTextPlaceholder"
                              arguments:@[ @(client) ]];
}

- (void)flutterTextInputView:(FlutterTextInputView*)textInputView
    didResignFirstResponderWithTextInputClient:(int)client {
  // When flutter text input view resign first responder, send a message to
  // framework to ensure the focus state is correct. This is useful when close
  // keyboard from platform side.
  [_textInputChannel.get() invokeMethod:@"TextInputClient.onConnectionClosed"
                              arguments:@[ @(client) ]];

  // Platform view's first responder detection logic:
  //
  // All text input widgets (e.g. EditableText) are backed by a dummy UITextInput view
  // in the TextInputPlugin. When this dummy UITextInput view resigns first responder,
  // check if any platform view becomes first responder. If any platform view becomes
  // first responder, send a "viewFocused" channel message to inform the framework to un-focus
  // the previously focused text input.
  //
  // Caveat:
  // 1. This detection logic does not cover the scenario when a platform view becomes
  // first responder without any flutter text input resigning its first responder status
  // (e.g. user tapping on platform view first). For now it works fine because the TextInputPlugin
  // does not track the focused platform view id (which is different from Android implementation).
  //
  // 2. This detection logic assumes that all text input widgets are backed by a dummy
  // UITextInput view in the TextInputPlugin, which may not hold true in the future.

  // Have to check in the next run loop, because iOS requests the previous first responder to
  // resign before requesting the next view to become first responder.
  dispatch_async(dispatch_get_main_queue(), ^(void) {
    long platform_view_id = self.platformViewsController->FindFirstResponderPlatformViewId();
    if (platform_view_id == -1) {
      return;
    }

    [_platformViewsChannel.get() invokeMethod:@"viewFocused" arguments:@(platform_view_id)];
  });
}

#pragma mark - Undo Manager Delegate

- (void)flutterUndoManagerPlugin:(FlutterUndoManagerPlugin*)undoManagerPlugin
         handleUndoWithDirection:(FlutterUndoRedoDirection)direction {
  NSString* action = (direction == FlutterUndoRedoDirectionUndo) ? @"undo" : @"redo";
  [_undoManagerChannel.get() invokeMethod:@"UndoManagerClient.handleUndo" arguments:@[ action ]];
}

#pragma mark - Screenshot Delegate

- (flutter::Rasterizer::Screenshot)takeScreenshot:(flutter::Rasterizer::ScreenshotType)type
                                  asBase64Encoded:(BOOL)base64Encode {
  FML_DCHECK(_shell) << "Cannot takeScreenshot without a shell";
  return _shell->Screenshot(type, base64Encode);
}

- (void)flutterViewAccessibilityDidCall {
  if (self.viewController.view.accessibilityElements == nil) {
    [self ensureSemanticsEnabled];
  }
}

- (NSObject<FlutterBinaryMessenger>*)binaryMessenger {
  return _binaryMessenger;
}

- (NSObject<FlutterTextureRegistry>*)textureRegistry {
  return _textureRegistry;
}

// For test only. Ideally we should create a dependency injector for all dependencies and
// remove this.
- (void)setBinaryMessenger:(FlutterBinaryMessengerRelay*)binaryMessenger {
  // Discard the previous messenger and keep the new one.
  _binaryMessenger.parent = nil;
  [_binaryMessenger release];
  _binaryMessenger = [binaryMessenger retain];
}

#pragma mark - FlutterBinaryMessenger

- (void)sendOnChannel:(NSString*)channel message:(NSData*)message {
  [self sendOnChannel:channel message:message binaryReply:nil];
}

- (void)sendOnChannel:(NSString*)channel
              message:(NSData*)message
          binaryReply:(FlutterBinaryReply)callback {
  NSParameterAssert(channel);
  NSAssert(_shell && _shell->IsSetup(),
           @"Sending a message before the FlutterEngine has been run.");
  fml::RefPtr<flutter::PlatformMessageResponseDarwin> response =
      (callback == nil) ? nullptr
                        : fml::MakeRefCounted<flutter::PlatformMessageResponseDarwin>(
                              ^(NSData* reply) {
                                callback(reply);
                              },
                              _shell->GetTaskRunners().GetPlatformTaskRunner());
  std::unique_ptr<flutter::PlatformMessage> platformMessage =
      (message == nil) ? std::make_unique<flutter::PlatformMessage>(channel.UTF8String, response)
                       : std::make_unique<flutter::PlatformMessage>(
                             channel.UTF8String, flutter::CopyNSDataToMapping(message), response);

  _shell->GetPlatformView()->DispatchPlatformMessage(std::move(platformMessage));
  // platformMessage takes ownership of response.
  // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks)
}

- (NSObject<FlutterTaskQueue>*)makeBackgroundTaskQueue {
  return flutter::PlatformMessageHandlerIos::MakeBackgroundTaskQueue();
}

- (FlutterBinaryMessengerConnection)setMessageHandlerOnChannel:(NSString*)channel
                                          binaryMessageHandler:
                                              (FlutterBinaryMessageHandler)handler {
  return [self setMessageHandlerOnChannel:channel binaryMessageHandler:handler taskQueue:nil];
}

- (FlutterBinaryMessengerConnection)
    setMessageHandlerOnChannel:(NSString*)channel
          binaryMessageHandler:(FlutterBinaryMessageHandler)handler
                     taskQueue:(NSObject<FlutterTaskQueue>* _Nullable)taskQueue {
  NSParameterAssert(channel);
  if (_shell && _shell->IsSetup()) {
    self.iosPlatformView->GetPlatformMessageHandlerIos()->SetMessageHandler(channel.UTF8String,
                                                                            handler, taskQueue);
    return _connections->AquireConnection(channel.UTF8String);
  } else {
    NSAssert(!handler, @"Setting a message handler before the FlutterEngine has been run.");
    // Setting a handler to nil for a channel that has not yet been set up is a no-op.
    return flutter::ConnectionCollection::MakeErrorConnection(-1);
  }
}

- (void)cleanUpConnection:(FlutterBinaryMessengerConnection)connection {
  if (_shell && _shell->IsSetup()) {
    std::string channel = _connections->CleanupConnection(connection);
    if (!channel.empty()) {
      self.iosPlatformView->GetPlatformMessageHandlerIos()->SetMessageHandler(channel.c_str(), nil,
                                                                              nil);
    }
  }
}

#pragma mark - FlutterTextureRegistry

- (int64_t)registerTexture:(NSObject<FlutterTexture>*)texture {
  int64_t textureId = _nextTextureId++;
  self.iosPlatformView->RegisterExternalTexture(textureId, texture);
  return textureId;
}

- (void)unregisterTexture:(int64_t)textureId {
  _shell->GetPlatformView()->UnregisterTexture(textureId);
}

- (void)textureFrameAvailable:(int64_t)textureId {
  _shell->GetPlatformView()->MarkTextureFrameAvailable(textureId);
}

- (NSString*)lookupKeyForAsset:(NSString*)asset {
  return [FlutterDartProject lookupKeyForAsset:asset];
}

- (NSString*)lookupKeyForAsset:(NSString*)asset fromPackage:(NSString*)package {
  return [FlutterDartProject lookupKeyForAsset:asset fromPackage:package];
}

- (id<FlutterPluginRegistry>)pluginRegistry {
  return self;
}

#pragma mark - FlutterPluginRegistry

- (NSObject<FlutterPluginRegistrar>*)registrarForPlugin:(NSString*)pluginKey {
  NSAssert(self.pluginPublications[pluginKey] == nil, @"Duplicate plugin key: %@", pluginKey);
  self.pluginPublications[pluginKey] = [NSNull null];
  FlutterEngineRegistrar* result = [[FlutterEngineRegistrar alloc] initWithPlugin:pluginKey
                                                                    flutterEngine:self];
  self.registrars[pluginKey] = result;
  return [result autorelease];
}

- (BOOL)hasPlugin:(NSString*)pluginKey {
  return _pluginPublications[pluginKey] != nil;
}

- (NSObject*)valuePublishedByPlugin:(NSString*)pluginKey {
  return _pluginPublications[pluginKey];
}

#pragma mark - Notifications

- (void)applicationWillEnterForeground:(NSNotification*)notification {
  [self setIsGpuDisabled:NO];
}

- (void)applicationDidEnterBackground:(NSNotification*)notification {
  [self setIsGpuDisabled:YES];
  [self notifyLowMemory];
}

- (void)onMemoryWarning:(NSNotification*)notification {
  [self notifyLowMemory];
}

- (void)setIsGpuDisabled:(BOOL)value {
  if (_shell) {
    _shell->SetGpuAvailability(value ? flutter::GpuAvailability::kUnavailable
                                     : flutter::GpuAvailability::kAvailable);
  }
  _isGpuDisabled = value;
}

#pragma mark - Locale updates

- (void)onLocaleUpdated:(NSNotification*)notification {
  // Get and pass the user's preferred locale list to dart:ui.
  NSMutableArray<NSString*>* localeData = [[[NSMutableArray alloc] init] autorelease];
  NSArray<NSString*>* preferredLocales = [NSLocale preferredLanguages];
  for (NSString* localeID in preferredLocales) {
    NSLocale* locale = [[[NSLocale alloc] initWithLocaleIdentifier:localeID] autorelease];
    NSString* languageCode = [locale objectForKey:NSLocaleLanguageCode];
    NSString* countryCode = [locale objectForKey:NSLocaleCountryCode];
    NSString* scriptCode = [locale objectForKey:NSLocaleScriptCode];
    NSString* variantCode = [locale objectForKey:NSLocaleVariantCode];
    if (!languageCode) {
      continue;
    }
    [localeData addObject:languageCode];
    [localeData addObject:(countryCode ? countryCode : @"")];
    [localeData addObject:(scriptCode ? scriptCode : @"")];
    [localeData addObject:(variantCode ? variantCode : @"")];
  }
  if (localeData.count == 0) {
    return;
  }
  [self.localizationChannel invokeMethod:@"setLocale" arguments:localeData];
}

- (void)waitForFirstFrame:(NSTimeInterval)timeout
                 callback:(void (^_Nonnull)(BOOL didTimeout))callback {
  dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0);
  dispatch_async(queue, ^{
    fml::TimeDelta waitTime = fml::TimeDelta::FromMilliseconds(timeout * 1000);
    BOOL didTimeout =
        self.shell.WaitForFirstFrame(waitTime).code() == fml::StatusCode::kDeadlineExceeded;
    dispatch_async(dispatch_get_main_queue(), ^{
      callback(didTimeout);
    });
  });
}

- (FlutterEngine*)spawnWithEntrypoint:(/*nullable*/ NSString*)entrypoint
                           libraryURI:(/*nullable*/ NSString*)libraryURI
                         initialRoute:(/*nullable*/ NSString*)initialRoute
                       entrypointArgs:(/*nullable*/ NSArray<NSString*>*)entrypointArgs {
  NSAssert(_shell, @"Spawning from an engine without a shell (possibly not run).");
  FlutterEngine* result = [[FlutterEngine alloc] initWithName:_labelPrefix
                                                      project:_dartProject.get()
                                       allowHeadlessExecution:_allowHeadlessExecution];
  flutter::RunConfiguration configuration =
      [_dartProject.get() runConfigurationForEntrypoint:entrypoint
                                           libraryOrNil:libraryURI
                                         entrypointArgs:entrypointArgs];

  fml::WeakPtr<flutter::PlatformView> platform_view = _shell->GetPlatformView();
  FML_DCHECK(platform_view);
  // Static-cast safe since this class always creates PlatformViewIOS instances.
  flutter::PlatformViewIOS* ios_platform_view =
      static_cast<flutter::PlatformViewIOS*>(platform_view.get());
  std::shared_ptr<flutter::IOSContext> context = ios_platform_view->GetIosContext();
  FML_DCHECK(context);

  // Lambda captures by pointers to ObjC objects are fine here because the
  // create call is synchronous.
  flutter::Shell::CreateCallback<flutter::PlatformView> on_create_platform_view =
      [result, context](flutter::Shell& shell) {
        [result recreatePlatformViewController];
        return std::make_unique<flutter::PlatformViewIOS>(
            shell, context, result->_platformViewsController, shell.GetTaskRunners());
      };

  flutter::Shell::CreateCallback<flutter::Rasterizer> on_create_rasterizer =
      [](flutter::Shell& shell) { return std::make_unique<flutter::Rasterizer>(shell); };

  std::string cppInitialRoute;
  if (initialRoute) {
    cppInitialRoute = [initialRoute UTF8String];
  }

  std::unique_ptr<flutter::Shell> shell = _shell->Spawn(
      std::move(configuration), cppInitialRoute, on_create_platform_view, on_create_rasterizer);

  result->_threadHost = _threadHost;
  result->_profiler = _profiler;
  result->_profiler_metrics = _profiler_metrics;
  result->_isGpuDisabled = _isGpuDisabled;
  [result setupShell:std::move(shell) withVMServicePublication:NO];
  return [result autorelease];
}

- (const flutter::ThreadHost&)threadHost {
  return *_threadHost;
}

- (FlutterDartProject*)project {
  return _dartProject.get();
}

- (BOOL)isUsingImpeller {
  return self.project.isImpellerEnabled;
}

@end

@implementation FlutterEngineRegistrar {
  NSString* _pluginKey;
}

- (instancetype)initWithPlugin:(NSString*)pluginKey flutterEngine:(FlutterEngine*)flutterEngine {
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  _pluginKey = [pluginKey copy];
  _flutterEngine = flutterEngine;
  return self;
}

- (void)dealloc {
  [_pluginKey release];
  [super dealloc];
}

- (NSObject<FlutterBinaryMessenger>*)messenger {
  return _flutterEngine.binaryMessenger;
}

- (NSObject<FlutterTextureRegistry>*)textures {
  return _flutterEngine.textureRegistry;
}

- (void)publish:(NSObject*)value {
  _flutterEngine.pluginPublications[_pluginKey] = value;
}

- (void)addMethodCallDelegate:(NSObject<FlutterPlugin>*)delegate
                      channel:(FlutterMethodChannel*)channel {
  [channel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
    [delegate handleMethodCall:call result:result];
  }];
}

- (void)addApplicationDelegate:(NSObject<FlutterPlugin>*)delegate {
  id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
  if ([appDelegate conformsToProtocol:@protocol(FlutterAppLifeCycleProvider)]) {
    id<FlutterAppLifeCycleProvider> lifeCycleProvider =
        (id<FlutterAppLifeCycleProvider>)appDelegate;
    [lifeCycleProvider addApplicationLifeCycleDelegate:delegate];
  }
}

- (NSString*)lookupKeyForAsset:(NSString*)asset {
  return [_flutterEngine lookupKeyForAsset:asset];
}

- (NSString*)lookupKeyForAsset:(NSString*)asset fromPackage:(NSString*)package {
  return [_flutterEngine lookupKeyForAsset:asset fromPackage:package];
}

- (void)registerViewFactory:(NSObject<FlutterPlatformViewFactory>*)factory
                     withId:(NSString*)factoryId {
  [self registerViewFactory:factory
                                withId:factoryId
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
}

- (void)registerViewFactory:(NSObject<FlutterPlatformViewFactory>*)factory
                              withId:(NSString*)factoryId
    gestureRecognizersBlockingPolicy:
        (FlutterPlatformViewGestureRecognizersBlockingPolicy)gestureRecognizersBlockingPolicy {
  [_flutterEngine platformViewsController]->RegisterViewFactory(factory, factoryId,
                                                                gestureRecognizersBlockingPolicy);
}

@end
