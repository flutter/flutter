#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterWindowController.h"

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterCodecs.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#include "flutter/shell/platform/common/isolate_scope.h"

struct FlutterWindowCreationRequest {
  double width;
  double height;
  double min_width;
  double min_height;
  double max_width;
  double max_height;
  void (*on_close)();
  void (*on_size_change)();
};

/// A delegate for a Flutter managed window.
@interface FlutterWindowOwner : NSObject <NSWindowDelegate> {
  /// Strong reference to the window. This is the only strong reference to the
  /// window.
  NSWindow* _window;
  FlutterViewController* _flutterViewController;
  flutter::Isolate _isolate;
  FlutterWindowCreationRequest _creationRequest;
}

@property(readonly, nonatomic) NSWindow* window;
@property(readonly, nonatomic) FlutterViewController* flutterViewController;

- (instancetype)initWithWindow:(NSWindow*)window
         flutterViewController:(FlutterViewController*)viewController
               creationRequest:(const FlutterWindowCreationRequest&)creationRequest;

@end

@implementation FlutterWindowOwner

@synthesize window = _window;
@synthesize flutterViewController = _flutterViewController;

- (instancetype)initWithWindow:(NSWindow*)window
         flutterViewController:(FlutterViewController*)viewController
               creationRequest:(const FlutterWindowCreationRequest&)creationRequest {
  if (self = [super init]) {
    _window = window;
    _flutterViewController = viewController;
    _creationRequest = creationRequest;
  }
  return self;
}

- (void)windowDidBecomeKey:(NSNotification*)notification {
  [_flutterViewController.engine windowDidBecomeKey:_flutterViewController.viewIdentifier];
}

- (void)windowDidResignKey:(NSNotification*)notification {
  [_flutterViewController.engine windowDidResignKey:_flutterViewController.viewIdentifier];
}

- (BOOL)windowShouldClose:(NSWindow*)sender {
  flutter::IsolateScope isolate_scope(_isolate);
  _creationRequest.on_close();
  return NO;
}

- (void)windowDidResize:(NSNotification*)notification {
  flutter::IsolateScope isolate_scope(_isolate);
  _creationRequest.on_size_change();
}

@end

@interface FlutterWindowController () {
  NSMutableArray<FlutterWindowOwner*>* _windows;
}

@end

@implementation FlutterWindowController

- (instancetype)init {
  self = [super init];
  if (self != nil) {
    _windows = [NSMutableArray array];
  }
  return self;
}

- (FlutterViewIdentifier)createRegularWindow:(const FlutterWindowCreationRequest*)request {
  FlutterViewController* c = [[FlutterViewController alloc] initWithEngine:_engine
                                                                   nibName:nil
                                                                    bundle:nil];

  NSWindow* window = [[NSWindow alloc] init];
  // If this is not set there will be double free on window close when
  // using ARC.
  [window setReleasedWhenClosed:NO];

  window.contentViewController = c;
  [window setContentSize:NSMakeSize(request->width, request->height)];
  window.styleMask = NSWindowStyleMaskResizable | NSWindowStyleMaskTitled |
                     NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable;
  [window setIsVisible:YES];
  [window makeKeyAndOrderFront:nil];

  FlutterWindowOwner* w = [[FlutterWindowOwner alloc] initWithWindow:window
                                               flutterViewController:c
                                                     creationRequest:*request];
  window.delegate = w;
  [_windows addObject:w];

  return c.viewIdentifier;
}

- (void)destroyWindow:(NSWindow*)window {
  FlutterWindowOwner* owner = nil;
  for (FlutterWindowOwner* o in _windows) {
    if (o.window == window) {
      owner = o;
      break;
    }
  }
  if (owner != nil) {
    [_windows removeObject:owner];
    [owner.flutterViewController dispose];
    owner.window.delegate = nil;
    [owner.window close];
  }
}

@end

extern "C" {
// NOLINTBEGIN(google-objc-function-naming)

FLUTTER_DARWIN_EXPORT
int64_t flutter_create_regular_window(int64_t engine_id,
                                      const FlutterWindowCreationRequest* request) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine enableMultiView];
  return [engine.windowController createRegularWindow:request];
}

FLUTTER_DARWIN_EXPORT
void flutter_destroy_window(int64_t engine_id, void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  [engine.windowController destroyWindow:w];
}

FLUTTER_DARWIN_EXPORT
void* flutter_get_window_handle(int64_t engine_id, FlutterViewIdentifier view_id) {
  FlutterEngine* engine = [FlutterEngine engineForIdentifier:engine_id];
  FlutterViewController* controller = [engine viewControllerForIdentifier:view_id];
  return (__bridge void*)controller.view.window;
}

struct FlutterWindowSize {
  double width;
  double height;
};

FLUTTER_DARWIN_EXPORT
void flutter_get_window_size(void* window, FlutterWindowSize* size) {
  NSWindow* w = (__bridge NSWindow*)window;
  size->width = w.frame.size.width;
  size->height = w.frame.size.height;
}

FLUTTER_DARWIN_EXPORT
void flutter_set_window_size(void* window, double width, double height) {
  NSWindow* w = (__bridge NSWindow*)window;
  [w setContentSize:NSMakeSize(width, height)];
}

FLUTTER_DARWIN_EXPORT
void flutter_set_window_title(void* window, const char* title) {
  NSWindow* w = (__bridge NSWindow*)window;
  w.title = [NSString stringWithUTF8String:title];
}

FLUTTER_DARWIN_EXPORT
int64_t flutter_get_window_state(void* window) {
  NSWindow* w = (__bridge NSWindow*)window;
  if (w.isZoomed) {
    return 1;
  } else if (w.isMiniaturized) {
    return 2;
  } else {
    return 0;
  }
}

FLUTTER_DARWIN_EXPORT
void flutter_set_window_state(void* window, int64_t state) {
  NSWindow* w = (__bridge NSWindow*)window;
  if (state == 1) {
    [w zoom:nil];
  } else if (state == 2) {
    [w miniaturize:nil];
  } else {
    if (w.isMiniaturized) {
      [w deminiaturize:nil];
    } else if (w.isZoomed) {
      [w zoom:nil];
    } else {
      bool isFullScreen = (w.styleMask & NSWindowStyleMaskFullScreen) != 0;
      if (isFullScreen) {
        [w toggleFullScreen:nil];
      }
    }
  }
}

// NOLINTEND(google-objc-function-naming)
}  // extern "C"
