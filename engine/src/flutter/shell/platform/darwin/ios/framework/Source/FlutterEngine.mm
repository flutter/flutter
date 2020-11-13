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
#import "flutter/shell/platform/darwin/common/command_line.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterBinaryMessengerRelay.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterObservatoryPublisher.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/connection_collection.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/platform_message_response_darwin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/profiler_metrics_ios.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#import "flutter/shell/platform/darwin/ios/rendering_api_selection.h"
#include "flutter/shell/profiling/sampling_profiler.h"

NSString* const FlutterDefaultDartEntrypoint = nil;
NSString* const FlutterDefaultInitialRoute = nil;
static constexpr int kNumProfilerSamplesPerSec = 5;

@interface FlutterEngineRegistrar : NSObject <FlutterPluginRegistrar>
@property(nonatomic, assign) FlutterEngine* flutterEngine;
- (instancetype)initWithPlugin:(NSString*)pluginKey flutterEngine:(FlutterEngine*)flutterEngine;
@end

@interface FlutterEngine () <FlutterTextInputDelegate, FlutterBinaryMessenger>
// Maintains a dictionary of plugin names that have registered with the engine.  Used by
// FlutterEngineRegistrar to implement a FlutterPluginRegistrar.
@property(nonatomic, readonly) NSMutableDictionary* pluginPublications;
@property(nonatomic, readonly) NSMutableDictionary<NSString*, FlutterEngineRegistrar*>* registrars;

@property(nonatomic, readwrite, copy) NSString* isolateId;
@property(nonatomic, copy) NSString* initialRoute;
@property(nonatomic, retain) id<NSObject> flutterViewControllerWillDeallocObserver;
@end

@implementation FlutterEngine {
  fml::scoped_nsobject<FlutterDartProject> _dartProject;
  flutter::ThreadHost _threadHost;
  std::unique_ptr<flutter::Shell> _shell;
  NSString* _labelPrefix;
  std::unique_ptr<fml::WeakPtrFactory<FlutterEngine>> _weakFactory;

  fml::WeakPtr<FlutterViewController> _viewController;
  fml::scoped_nsobject<FlutterObservatoryPublisher> _publisher;

  std::shared_ptr<flutter::FlutterPlatformViewsController> _platformViewsController;
  flutter::IOSRenderingAPI _renderingApi;
  std::unique_ptr<flutter::ProfilerMetricsIOS> _profiler_metrics;
  std::unique_ptr<flutter::SamplingProfiler> _profiler;

  // Channels
  fml::scoped_nsobject<FlutterPlatformPlugin> _platformPlugin;
  fml::scoped_nsobject<FlutterTextInputPlugin> _textInputPlugin;
  fml::scoped_nsobject<FlutterMethodChannel> _localizationChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _navigationChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _platformChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _platformViewsChannel;
  fml::scoped_nsobject<FlutterMethodChannel> _textInputChannel;
  fml::scoped_nsobject<FlutterBasicMessageChannel> _lifecycleChannel;
  fml::scoped_nsobject<FlutterBasicMessageChannel> _systemChannel;
  fml::scoped_nsobject<FlutterBasicMessageChannel> _settingsChannel;
  fml::scoped_nsobject<FlutterBasicMessageChannel> _keyEventChannel;

  int64_t _nextTextureId;

  BOOL _allowHeadlessExecution;
  FlutterBinaryMessengerRelay* _binaryMessenger;
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
  self = [super init];
  NSAssert(self, @"Super init cannot be nil");
  NSAssert(labelPrefix, @"labelPrefix is required");

  _allowHeadlessExecution = allowHeadlessExecution;
  _labelPrefix = [labelPrefix copy];

  _weakFactory = std::make_unique<fml::WeakPtrFactory<FlutterEngine>>(self);

  if (project == nil)
    _dartProject.reset([[FlutterDartProject alloc] init]);
  else
    _dartProject.reset([project retain]);

  if (!EnableTracingIfNecessary([_dartProject.get() settings])) {
    NSLog(
        @"Cannot create a FlutterEngine instance in debug mode without Flutter tooling or "
        @"Xcode.\n\nTo launch in debug mode in iOS 14+, run flutter run from Flutter tools, run "
        @"from an IDE with a Flutter IDE plugin or run the iOS project from Xcode.\nAlternatively "
        @"profile and release mode apps can be launched from the home screen.");
    [self release];
    return nil;
  }

  _pluginPublications = [NSMutableDictionary new];
  _registrars = [[NSMutableDictionary alloc] init];
  [self recreatePlatformViewController];

  _binaryMessenger = [[FlutterBinaryMessengerRelay alloc] initWithParent:self];
  _connections.reset(new flutter::ConnectionCollection());

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(onMemoryWarning:)
                 name:UIApplicationDidReceiveMemoryWarningNotification
               object:nil];

  [center addObserver:self
             selector:@selector(applicationDidEnterBackground:)
                 name:UIApplicationDidEnterBackgroundNotification
               object:nil];

  [center addObserver:self
             selector:@selector(applicationBecameActive:)
                 name:UIApplicationDidBecomeActiveNotification
               object:nil];

  [center addObserver:self
             selector:@selector(applicationWillResignActive:)
                 name:UIApplicationWillResignActiveNotification
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
  [_binaryMessenger release];

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
  self.platformView->SetViewportMetrics(std::move(viewportMetrics));
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

- (void)ensureSemanticsEnabled {
  self.iosPlatformView->SetSemanticsEnabled(true);
}

- (void)setViewController:(FlutterViewController*)viewController {
  FML_DCHECK(self.iosPlatformView);
  _viewController =
      viewController ? [viewController getWeakPtr] : fml::WeakPtr<FlutterViewController>();
  self.iosPlatformView->SetOwnerViewController(_viewController);
  [self maybeSetupPlatformViewChannels];

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
  if (!_allowHeadlessExecution) {
    [self destroyContext];
  } else {
    flutter::PlatformViewIOS* platform_view = [self iosPlatformView];
    if (platform_view) {
      platform_view->SetOwnerViewController({});
    }
  }
  _viewController.reset();
}

- (void)destroyContext {
  [self resetChannels];
  self.isolateId = nil;
  _shell.reset();
  _profiler.reset();
  _threadHost.Reset();
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
- (FlutterMethodChannel*)localizationChannel {
  return _localizationChannel.get();
}
- (FlutterMethodChannel*)navigationChannel {
  return _navigationChannel.get();
}
- (FlutterMethodChannel*)platformChannel {
  return _platformChannel.get();
}
- (FlutterMethodChannel*)textInputChannel {
  return _textInputChannel.get();
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

- (void)resetChannels {
  _localizationChannel.reset();
  _navigationChannel.reset();
  _platformChannel.reset();
  _platformViewsChannel.reset();
  _textInputChannel.reset();
  _lifecycleChannel.reset();
  _systemChannel.reset();
  _settingsChannel.reset();
  _keyEventChannel.reset();
}

- (void)startProfiler {
  FML_DCHECK(!_threadHost.name_prefix.empty());
  _profiler_metrics = std::make_unique<flutter::ProfilerMetricsIOS>();
  _profiler = std::make_unique<flutter::SamplingProfiler>(
      _threadHost.name_prefix.c_str(), _threadHost.profiler_thread->GetTaskRunner(),
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

  _textInputPlugin.reset([[FlutterTextInputPlugin alloc] init]);
  _textInputPlugin.get().textInputDelegate = self;

  _platformPlugin.reset([[FlutterPlatformPlugin alloc] initWithEngine:[self getWeakPtr]]);
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
  }
}

- (flutter::Rasterizer::Screenshot)screenshot:(flutter::Rasterizer::ScreenshotType)type
                                 base64Encode:(bool)base64Encode {
  return self.shell.Screenshot(type, base64Encode);
}

- (void)launchEngine:(NSString*)entrypoint libraryURI:(NSString*)libraryOrNil {
  // Launch the Dart application with the inferred run configuration.
  self.shell.RunEngine([_dartProject.get() runConfigurationForEntrypoint:entrypoint
                                                            libraryOrNil:libraryOrNil]);
}

- (void)setupShell:(std::unique_ptr<flutter::Shell>)shell
    withObservatoryPublication:(BOOL)doesObservatoryPublication {
  _shell = std::move(shell);
  [self setupChannels];
  [self onLocaleUpdated:nil];
  [self initializeDisplays];
  _publisher.reset([[FlutterObservatoryPublisher alloc]
      initWithEnableObservatoryPublication:doesObservatoryPublication]);
  [self maybeSetupPlatformViewChannels];
  _shell->GetIsGpuDisabledSyncSwitch()->SetSwitch(_isGpuDisabled ? true : false);
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

  uint32_t threadHostType = flutter::ThreadHost::Type::UI | flutter::ThreadHost::Type::GPU |
                            flutter::ThreadHost::Type::IO;
  if ([FlutterEngine isProfilerEnabled]) {
    threadHostType = threadHostType | flutter::ThreadHost::Type::Profiler;
  }
  return {threadLabel.UTF8String,  // label
          threadHostType};
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
  FlutterView.forceSoftwareRendering = settings.enable_software_rendering;

  auto platformData = [_dartProject.get() defaultPlatformData];

  if (libraryURI) {
    FML_DCHECK(entrypoint) << "Must specify entrypoint if specifying library";
    settings.advisory_script_entrypoint = entrypoint.UTF8String;
    settings.advisory_script_uri = libraryURI.UTF8String;
  } else if (entrypoint) {
    settings.advisory_script_entrypoint = entrypoint.UTF8String;
    settings.advisory_script_uri = std::string("main.dart");
  } else {
    settings.advisory_script_entrypoint = std::string("main");
    settings.advisory_script_uri = std::string("main.dart");
  }

  NSString* threadLabel = [FlutterEngine generateThreadLabel:_labelPrefix];
  _threadHost = [FlutterEngine makeThreadHost:threadLabel];

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
                                    _threadHost.raster_thread->GetTaskRunner(),      // raster
                                    _threadHost.ui_thread->GetTaskRunner(),          // ui
                                    _threadHost.io_thread->GetTaskRunner()           // io
  );

  // Create the shell. This is a blocking operation.
  std::unique_ptr<flutter::Shell> shell =
      flutter::Shell::Create(std::move(task_runners),  // task runners
                             std::move(platformData),  // window data
                             std::move(settings),      // settings
                             on_create_platform_view,  // platform view creation
                             on_create_rasterizer      // rasterzier creation
      );

  if (shell == nullptr) {
    FML_LOG(ERROR) << "Could not start a shell FlutterEngine with entrypoint: "
                   << entrypoint.UTF8String;
  } else {
    [self setupShell:std::move(shell)
        withObservatoryPublication:settings.enable_observatory_publication];
    if ([FlutterEngine isProfilerEnabled]) {
      [self startProfiler];
    }
  }

  return _shell != nullptr;
}

- (void)initializeDisplays {
  double refresh_rate = [[[DisplayLinkManager alloc] init] displayRefreshRate];
  auto display = flutter::Display(refresh_rate);
  _shell->OnDisplayUpdates(flutter::DisplayUpdateType::kStartup, {display});
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
  if ([self createShell:entrypoint libraryURI:libraryURI initialRoute:initialRoute]) {
    [self launchEngine:entrypoint libraryURI:libraryURI];
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

- (void)updateEditingClient:(int)client withState:(NSDictionary*)state {
  [_textInputChannel.get() invokeMethod:@"TextInputClient.updateEditingState"
                              arguments:@[ @(client), state ]];
}

- (void)updateEditingClient:(int)client withState:(NSDictionary*)state withTag:(NSString*)tag {
  [_textInputChannel.get() invokeMethod:@"TextInputClient.updateEditingStateWithTag"
                              arguments:@[ @(client), @{tag : state} ]];
}

- (void)updateFloatingCursor:(FlutterFloatingCursorDragState)state
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

- (void)performAction:(FlutterTextInputAction)action withClient:(int)client {
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

- (void)showAutocorrectionPromptRectForStart:(NSUInteger)start
                                         end:(NSUInteger)end
                                  withClient:(int)client {
  [_textInputChannel.get() invokeMethod:@"TextInputClient.showAutocorrectionPromptRect"
                              arguments:@[ @(client), @(start), @(end) ]];
}

#pragma mark - Screenshot Delegate

- (flutter::Rasterizer::Screenshot)takeScreenshot:(flutter::Rasterizer::ScreenshotType)type
                                  asBase64Encoded:(BOOL)base64Encode {
  FML_DCHECK(_shell) << "Cannot takeScreenshot without a shell";
  return _shell->Screenshot(type, base64Encode);
}

- (NSObject<FlutterBinaryMessenger>*)binaryMessenger {
  return _binaryMessenger;
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
  fml::RefPtr<flutter::PlatformMessage> platformMessage =
      (message == nil) ? fml::MakeRefCounted<flutter::PlatformMessage>(channel.UTF8String, response)
                       : fml::MakeRefCounted<flutter::PlatformMessage>(
                             channel.UTF8String, flutter::GetVectorFromNSData(message), response);

  _shell->GetPlatformView()->DispatchPlatformMessage(platformMessage);
}

- (FlutterBinaryMessengerConnection)setMessageHandlerOnChannel:(NSString*)channel
                                          binaryMessageHandler:
                                              (FlutterBinaryMessageHandler)handler {
  NSParameterAssert(channel);
  if (_shell && _shell->IsSetup()) {
    self.iosPlatformView->GetPlatformMessageRouter().SetMessageHandler(channel.UTF8String, handler);
    return _connections->AquireConnection(channel.UTF8String);
  } else {
    NSAssert(!handler, @"Setting a message handler before the FlutterEngine has been run.");
    // Setting a handler to nil for a not setup channel is a noop.
    return flutter::ConnectionCollection::MakeErrorConnection(-1);
  }
}

- (void)cleanupConnection:(FlutterBinaryMessengerConnection)connection {
  if (_shell && _shell->IsSetup()) {
    std::string channel = _connections->CleanupConnection(connection);
    if (!channel.empty()) {
      self.iosPlatformView->GetPlatformMessageRouter().SetMessageHandler(channel.c_str(), nil);
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

- (void)applicationBecameActive:(NSNotification*)notification {
  [self setIsGpuDisabled:NO];
}

- (void)applicationWillResignActive:(NSNotification*)notification {
  [self setIsGpuDisabled:YES];
}

- (void)applicationDidEnterBackground:(NSNotification*)notification {
  [self notifyLowMemory];
}

- (void)onMemoryWarning:(NSNotification*)notification {
  [self notifyLowMemory];
}

- (void)setIsGpuDisabled:(BOOL)value {
  if (_shell) {
    _shell->GetIsGpuDisabledSyncSwitch()->SetSwitch(value ? true : false);
  }
  _isGpuDisabled = value;
}

#pragma mark - Locale updates

- (void)onLocaleUpdated:(NSNotification*)notification {
  // [NSLocale currentLocale] provides an iOS resolved locale if the
  // supported locales are exposed to the iOS embedder. Here, we get
  // currentLocale and pass it to dart:ui
  NSMutableArray<NSString*>* localeData = [[NSMutableArray new] autorelease];
  NSLocale* platformResolvedLocale = [NSLocale currentLocale];
  NSString* languageCode = [platformResolvedLocale objectForKey:NSLocaleLanguageCode];
  NSString* countryCode = [platformResolvedLocale objectForKey:NSLocaleCountryCode];
  NSString* scriptCode = [platformResolvedLocale objectForKey:NSLocaleScriptCode];
  NSString* variantCode = [platformResolvedLocale objectForKey:NSLocaleVariantCode];
  if (languageCode) {
    [localeData addObject:languageCode];
    [localeData addObject:(countryCode ? countryCode : @"")];
    [localeData addObject:(scriptCode ? scriptCode : @"")];
    [localeData addObject:(variantCode ? variantCode : @"")];
  }
  if (localeData.count != 0) {
    [self.localizationChannel invokeMethod:@"setPlatformResolvedLocale" arguments:localeData];
  }

  // Get and pass the user's preferred locale list to dart:ui
  localeData = [[NSMutableArray new] autorelease];
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
  return _flutterEngine;
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
